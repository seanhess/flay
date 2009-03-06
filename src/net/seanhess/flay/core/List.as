package net.seanhess.flay.core
{
	
import flash.display.DisplayObject;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;

import mx.collections.ArrayCollection;
import mx.collections.IList;
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
	 * Recycled renderers
	 */
	protected var recycle:Array;
	
	/**
	 * The item renderer to create for each item
	 */
	public function set itemRenderer(value:Object):void
	{
		if (value is String)
			value = new ClassFactory(getDefinitionByName(value as String) as Class);
		
		else if (value is Class)
			value = new ClassFactory(value as Class);
			
		if (value is IFactory)
			renderer = value as IFactory;
		
		else 
			throw new Error("item Renderer was not a class or factory");
			
		recycle = [];
	} 
	
	public function get itemRenderer():Object
	{
		return renderer;
	}
	
	public var renderer:IFactory = new ClassFactory(Label); 
		
	/**
	 * Returns all the renderers, referenced by item. These 
	 * are renderers that are actually in the list, displayed
	 * and have data associated with them
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
	    
	    else if (value is IList)
	    {
	    	collection = value as IList;
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
    	if (event.kind == CollectionEventKind.UPDATE)
    		return;
    	
    	collectionChange = true;
    	changes.push(event);
    	invalidateProperties();
    }
    
    /**
    * Make the change for each one that has happened since we last checked
    * 
    * If there was only one change, then perform it.
    * 
    * Otherwise, just do a full reset
    */
    override protected function commitProperties():void
    {
    	super.commitProperties();
    	
    	if (collectionChange)
    	{
    		collectionChange = false;
    		
    		if (changes.length > 0)
    		{
	    		if (changes.length == 1)
	    			makeChange(changes.pop());
	    			
	    		else
	    		{
	    			makeChange(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.RESET));
	    		}
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
				addChange(changeEvent);
				break;
			case CollectionEventKind.REMOVE:
				removeChange(changeEvent);
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
			case CollectionEventKind.UPDATE:	// update doesn't need to do anything
				break;
			case CollectionEventKind.REFRESH:
			default:
				differentialBuild();
				break;
		}
    }
    
    protected function addChange(event:CollectionEvent):void
    {
    	eachItemMatched(event, function(item:*, index:int):void {
    		if (index > -1)							// something weird is going on otherwise
    			add(item, getRenderer(), index);
    	});
    }
    
    protected function removeChange(event:CollectionEvent):void
    {
    	eachItemMatched(event, function(item:*, index:int):void {
			remove(itemRenderers[itemKey(item)]);
    	});
    }
    
    protected function eachItemMatched(event:CollectionEvent, callback:Function):void
    {
    	var items:Array = event.items;
    	
    	var i:int = 0;
    	while(i < items.length)
    	{
    		var item:* = items[i++];
    		
    		try
    		{
	    		var index:int = collection.getItemIndex(item);
	    		callback(item, index);
    		}
    		catch (e:Error)
    		{
    			continue; 	// skip out!
    		}
    	}
    }
    
    protected function updateData(renderer:IDataRenderer, item:Object):void
    {
    	if (renderer == null)
    		throw new Error("Renderer was null. Error in Flay.List");
    	
    	if (renderer.data == null)
    		throw new Error("Renderer data was not set. Error in Flay.List");
    		
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
    	if (renderer == null)
    		return;
    		
    	var info:RendererInfo = renderer["data"] as RendererInfo;
    		
    	if (this.contains(renderer))
    	{
    		removeChild(renderer);	
			recycle.push(renderer);
    	}
    	
    	if (info && info.source)
    	{
    		delete itemRenderers[info.source];
    	}
    	
    	updateData(renderer as IDataRenderer, null);
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
				add(item, getRenderer(), i);
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
    	
    	for each (var renderer:DisplayObject in this.getChildren())
    	{
    		removeChild(renderer);
    		recycle.push(renderer);
    	}
    	
    	var i:int = 0;
    	for each (var item:Object in collection)
    	{
    		add(item, getRenderer(), i);
    		i++; 
    	}
    }
    
    protected function init():void
    {
		itemRenderers = new Dictionary(true);
    }		
    
    /**
    * Actually creates a renderer
    */
    protected function createRenderer():UIComponent
    {
    	return renderer.newInstance() as UIComponent;
    }
    
    /**
    * Returns a renderer from the recycle pile if there are any
    * or creates one
    */
    protected function getRenderer():UIComponent
    {
    	var renderer:UIComponent = recycle.pop();
    	
    	if (renderer == null)
    		renderer = createRenderer();
    	
    	return renderer;
    }
    
    protected function itemKey(item:Object):Object
    {
    	if (item is IUID)
    		return (item as IUID).uid;
    		
    	else if (item.hasOwnProperty("id"))
    		return item.id;
    		
    	else if (item is Array || item is IList)
    		throw new Error("You have a nested array");
    		
    	else
    		return item;
    }
    			

	/**
	 * Internal list of itemRenderers
	 */
	protected var itemRenderers:Dictionary = new Dictionary(true);
	
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
    protected var collection:IList;
    

	
}
}