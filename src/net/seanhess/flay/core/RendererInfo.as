package net.seanhess.flay.core
{
	[Bindable]
	public class RendererInfo
	{
		/**
		 * The data for the row
		 */
		public var source:*;
		
		/**
		 * Whether the row is odd or not 
		 */
		public var odd:Boolean = false;
		
		/**
		 * Allow people to pass in anything they want here
		 * from the outside? This should be a data object, not
		 * another view to call 
		 */
		public var resource:Object;
	}
}