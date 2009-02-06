package com.lightlayout
{
	import mx.core.IChildList;
	
	public interface ISBoxLayout
	{
		/**
		 * allows the children to be sized and reset from the outside 
		 */
		function updateDisplayList(children:Array, width:Number, height:Number):void;	
	}
}