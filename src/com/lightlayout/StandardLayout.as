package com.lightlayout
{
	public class StandardLayout implements ISBoxLayout
	{
		public static const VERTICAL:String="vertical";
		public static const HORIZONTAL:String="horizontal";
		public static const ABSOLUTE:String="absolute";

		public var layout:String = VERTICAL;
		
		public function updateDisplayList(children:Array, width:Number, height:Number):void
		{
			return;
		}
	}
} 