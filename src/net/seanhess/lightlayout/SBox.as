package net.seanhess.lightlayout
{
	import mx.core.LayoutContainer;
	
	/**
	 * Superbox! It extends LayoutContainer, making it easier to access, but also allows for externally
	 * setting layoutManager
	 */
	public class SBox extends LayoutContainer
	{
		/**
		 * You can override the layout of the components by setting this bad boy
		 */		
		public function set layoutManager(value:ISBoxLayout):void
		{
			if (value is StandardLayout)
			{
				layout = (value as StandardLayout).layout;
			}
			
			_layoutManager = value;
			invalidateDisplayList();			
		}
		
		public function get layoutManager():ISBoxLayout
		{
			return _layoutManager;
		}
		
		protected var _layoutManager:ISBoxLayout;
	
		/**
	     * Possible to override how this works ;)
	     */
	    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	    {    	
	    	// 1 // Check to see what layout we're using // 
	    	
	    	super.updateDisplayList(unscaledWidth, unscaledHeight);

	    	if (layoutManager)
	    		layoutManager.updateDisplayList(this.getChildren(), unscaledWidth, unscaledHeight);
	    }

	}
}