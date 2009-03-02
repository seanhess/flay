package net.seanhess.lightlayout
{
	import flash.display.DisplayObject;
	
	public class FlowLayout implements ISBoxLayout
	{
		public static const FLOW_HORIZONTAL:String="flowHorizontal";
		public static const FLOW_VERTICAL:String="flowVertical";
		
		public var direction:String = "horizontal";
		
		public var innerPadding:Number = 6;
		public var outerPadding:Number = 0;
		
		// Always assume fixed width of the parent! // 
		public function updateDisplayList(children:Array, width:Number, height:Number):void
		{
			var xProp:String = (direction == "horizontal") ? "x" : "y";
			var yProp:String = (direction == "horizontal") ? "y" : "x";
			
			var widthProp:String = (direction == "horizontal") ? "width" : "height";
			var heightProp:String = (direction == "horizontal") ? "height" : "width";
			
			var widthValue:Number = (direction == "horizontal") ? width : height;
			
			var offsetMajor:Number = outerPadding;
			var offsetMinor:Number = outerPadding;
			var rowSize:Number = 0;
			
			for each (var child:DisplayObject in children)
			{
				// rowChange
				if (offsetMajor + child[widthProp] + outerPadding > widthValue)
				{
					offsetMajor = innerPadding;
					offsetMinor += rowSize + innerPadding;
				}
				
				child[xProp] = offsetMajor;
				child[yProp] = offsetMinor;
				
				if (child[heightProp] > rowSize)
					rowSize = child[heightProp];
				
				offsetMajor += child[widthProp] + innerPadding;	
			}
		}
	}
}