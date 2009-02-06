package com.lightlayout
{
	
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.Label;
import mx.core.ClassFactory;
import mx.core.IDataRenderer;
import mx.core.IFactory;
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
public class LightList extends SBox
{
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
    
    protected function updateData(renderer:UIComponent, item:Object):void
    {
    	if (renderer is IDataRenderer)
			(renderer as IDataRenderer).data = item;
    }
    
    protected function add(item:Object, renderer:UIComponent, location:int):void
    {
		updateData(renderer, item);
		addChildAt(renderer, location);
		itemRenderers[item] = renderer;
    }
    
    protected function remove(renderer:UIComponent):void
    {    	
    	updateData(renderer, null);
    	if (this.contains(renderer))
    		removeChildAt(getChildIndex(renderer));	
    }
    
    protected function moved(oldLocation:int, newLocation:int):void
    {    	
    	// move the renderer // 
    	var renderer:UIComponent = getChildAt(oldLocation) as UIComponent;
    	
    	setChildIndex(renderer, newLocation);
    }
    
    protected function replace(location:int):void
    {
    	var renderer:UIComponent = getChildAt(location) as UIComponent;
    		
    	if (renderer is IDataRenderer)
			(renderer as IDataRenderer).data = collection.getItemAt(location);
    }
    
    protected function differentialBuild():void
    {
		var checkedRenderers:Dictionary = new Dictionary(true);
			
		// Scan through the dataProvider, looking for new adds or moves?
		for (var i:int = 0; i < collection.length; i++)
		{
			var item:Object = collection.getItemAt(i);
			
			// If it doesn't have a renderer ... create it (in the right place!)// 
			if (!itemRenderers[item])
			{
				add(item, createRenderer(), i);
			}
			
			// We've cleared this renderer // 
			checkedRenderers[itemRenderers[item]] = true; 
		}
		
		// Scan through the renderers, looking for removes
		for each (var existingRenderer:UIComponent in itemRenderers)
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
    	itemRenderers = new Dictionary(true);
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
		if (!itemRenderers)
			itemRenderers = new Dictionary(true);
    }		
    
    protected function createRenderer():UIComponent
    {
    	return itemRenderer.newInstance() as UIComponent;
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