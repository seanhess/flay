package net.seanhess.lightlayout
{
	
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.Label;
import mx.core.ClassFactory;
import mx.core.IDataRenderer;
import mx.core.IFactory;
import mx.core.IUID;
import mx.core.UIComponent;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind; 

/**
 * LightList creates a component for each item in the data provider. It doesn't
 * do any of the other crap that list does, like highlight and allow people to 
 * select items. It would probably be better termed a replacement for the 
 * repeater instead. 
 * 
 * The performance should be significantly better than either list or Repeater
 * and it will respond to updates in the list
 * 
 * Be sure to set the dataProvider to an array or ArrayCollection. 
 */
public class List extends SBox
{
	/**
	 * Information passed through to each renderer
	 */
	public var resource:Object;
	
	/**
	 * The item renderer to create for each item
	 */
	public var itemRenderer:IFactory = new ClassFactory(Label); 
		
	/**
	 * Returns all the renderers, referenced by item
	 */
	public function get renderers():Dictionary
	{
		return itemRenderers;	
	}
	
	/**
	 * dataProvider -- treat just like a List, but only accepts Arrays and ArrayCollections
	 */
	public function get dataProvider():Object
	{
	    return collection;
	}
		
	public function set dataProvider(value:Object):void
	{
	    if (collection)
	    {
	        collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
	    }
	
	    if (value is Array)
	    {
	        collection = new ArrayCollection(value as Array);
	    }
	    
	    else if (value is ArrayCollection)
	    {
	    	collection = value as ArrayCollection;
	    }

	    collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange, false, 0, true);
		
		var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
			event.kind = CollectionEventKind.RESET;

		onCollectionChange(event);
	}
	
	
	
	/**
	 * Defer changes, and save them
	 */
    protected function onCollectionChange(event:CollectionEvent):void
    {
    	collectionChange = true;
    	changes.push(event);
    	invalidateProperties();
    }
    
    /**
    * Make the change for each one that has happened since we last checked
    */
    override protected function commitProperties():void
    {
    	super.commitProperties();
    	
    	if (collectionChange)
    	{
    		collectionChange = false;
    		init();
    		
    		for each (var change:CollectionEvent in changes)
    		{
    			makeChange(change);
    		}
    		
    		changes = []; 
    	}
    }
    
    /**
    * Perform each change
    */
    protected function makeChange(changeEvent:CollectionEvent):void
    {
    	switch(changeEvent.kind)
		{
			case CollectionEventKind.ADD:
				var item:Object = collection.getItemAt(changeEvent.location);
				add(item, createRenderer(), changeEvent.location);
				break;
			case CollectionEventKind.REMOVE:
		    	var renderer:UIComponent = getChildAt(changeEvent.location) as UIComponent;
				remove(renderer);
				break;
			case CollectionEventKind.MOVE:
				moved(changeEvent.oldLocation, changeEvent.location);
				break;
			case CollectionEventKind.REPLACE:
				replace(changeEvent.location);
				break;
			case CollectionEventKind.RESET:
				reset();
				break;
			case CollectionEventKind.REFRESH:
			case CollectionEventKind.UPDATE:
			default:
				differentialBuild();
				break;
		}
    }
    
    protected function updateData(renderer:IDataRenderer, item:Object):void
    {
    	if (renderer.data == null)
    		throw new Error("Renderer data was not set. Error in LightList");
    		
		(renderer.data as RendererInfo).source = item;
    }
    
    protected function add(item:Object, renderer:UIComponent, location:int):void
    {
    	itemRenderers[itemKey(item)] = renderer;
    			
		var info:RendererInfo = new RendererInfo();
			info.odd = ((location % 2) == 1);
			info.source = item;
			info.resource = resource;
			
    	(renderer as IDataRenderer).data = info;
		
		addChildAt(renderer, location);
    }
    
    protected function remove(renderer:UIComponent):void
    {    	
    	updateData(renderer as IDataRenderer, null);
    	
    	if (this.contains(renderer))
    		removeChildAt(getChildIndex(renderer));	
    }
    
    protected function moved(oldLocation:int, newLocation:int):void
    {    	
    	var renderer:UIComponent = getChildAt(oldLocation) as UIComponent;
    	setChildIndex(renderer, newLocation);
    	
    	// update all the indices! // 
		for (var i:int = 0; i < collection.length; i++)
		{
			var item:Object = collection.getItemAt(i);
			((itemRenderers[itemKey(item)] as IDataRenderer).data as RendererInfo).odd = ((i % 2) == 1);
		}
    }
    
    protected function replace(location:int):void
    {
    	var renderer:UIComponent = getChildAt(location) as UIComponent;
    	updateData(renderer as IDataRenderer, collection.getItemAt(location));
    }
    
    protected function differentialBuild():void
    {
		var checkedRenderers:Dictionary = new Dictionary(true);
			
		// Scan through the dataProvider, looking for new adds or moves?
		for (var i:int = 0; i < collection.length; i++)
		{
			var item:Object = collection.getItemAt(i);
			
			// If it doesn't have a renderer ... create it (in the right place!)// 
			if (!itemRenderers[itemKey(item)])
			{
				add(item, createRenderer(), i);
			}
			
			// We've cleared this renderer // 
			checkedRenderers[itemRenderers[itemKey(item)]] = true; 
		}
		
		// Scan through the renderers, looking for removes
		for each (var existingRenderer:UIComponent in this.getChildren())
		{
			// remove any that weren't checked // 
			if (!checkedRenderers[existingRenderer])
			{
				remove(existingRenderer);
			}
		}
    }
    
    protected function reset():void
    {
    	init();
    	this.removeAllChildren();
    	
    	var i:int = 0;
    	for each (var item:Object in collection)
    	{
    		add(item, createRenderer(), i);
    		i++; 
    	}
    }
    
    protected function init():void
    {
		itemRenderers = new Dictionary(true);
    }		
    
    protected function createRenderer():UIComponent
    {
    	return itemRenderer.newInstance() as UIComponent;
    }
    
    protected function itemKey(item:Object):Object
    {
    	if (item is IUID)
    		return (item as IUID).uid;
    		
    	else if (item.hasOwnProperty("id"))
    		return item.id;
    		
    	else if (item is Array || item is ArrayCollection)
    		throw new Error("You have a nested array");
    		
    	else
    		return item;
    }
    			

	/**
	 * Internal list of itemRenderers
	 */
	protected var itemRenderers:Dictionary;
	
	/**
	 * Defer updates to the list
	 */
	protected var collectionChange:Boolean = false;
	
	/**
	 * List of changes since last update
	 */
	protected var changes:Array = [];
	
	/**
	 * The data internally
	 */
    protected var collection:ArrayCollection;
    

	
}
}