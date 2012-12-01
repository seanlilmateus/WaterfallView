class WaterfallLayout < UICollectionViewLayout
  attr_writer :delegate
  
  def init
    super.tap { commit_init }
  end
  
  def commit_init
    @column_count  ||= 2
    @item_width    ||= 140.0
    @section_inset ||= UIEdgeInsets.new
  end
  
  def column_count=(count)
    unless @column_count == count
      @column_count = count
      self.invalidateLayout
    end
  end
  
  def item_width=(width)
    unless @item_width == width
      @item_width = width
      self.invalidateLayout
    end
  end
  
  def section_inset=(inset)
    unless UIEdgeInsetsEqualToEdgeInsets(@section_inset, inset)
      @section_inset = inset
      self.invalidateLayout
    end
  end
  
  def dealloc
    NSLog("dealloc")
    @column_heights = nil
    @item_attrs = nil
  end
  
  def prepareLayout
    super
    
    @item_count = self.collectionView.numberOfItemsInSection(0)
    NSLog("this should never happens.") if @column_count < 1
    
    width = self.collectionView.frame.size.width - @section_inset.left - @section_inset.right
    @interitem_spacing = ((width - @column_count * @item_width) / (@column_count - 1)).floor.to_f.abs
    
    @item_attrs = []
    @column_heights = []
    @column_count.to_i.times { |idx| @column_heights << @section_inset.top }
    
    # Item will be put into shortest column.
    @item_count.to_i.times do |idx|
      path = NSIndexPath.indexPathForItem(idx, inSection:0)
      item_height = @delegate.collectionView(self.collectionView, layout:self, heightForItemAtIndexPath:path) if @delegate
          
      column_idx = shortest_column_index.to_i
      xoffset = @section_inset.left + (@item_width + @interitem_spacing) * column_idx
      yoffset = @column_heights[column_idx].floatValue
      item_center = CGPoint.new((xoffset + @item_width / 2).floor, (yoffset + item_height / 2).floor)
      
      UICollectionViewLayoutAttributes.layoutAttributesForCellWithIndexPath(path).tap do |attrs|
        attrs.size = CGSize.new(@item_width, item_height)
        attrs.center = item_center
        @item_attrs << attrs
      end
      @column_heights[column_idx] = yoffset + item_height + @interitem_spacing
    end
  end
  
  def collectionViewContentSize
    return CGSize.new if @item_count.zero?
    content_size = self.collectionView.frame.size
    column_idx = longest_column_index
    height = @column_heights[column_idx].floatValue
    content_size.height = height - @interitem_spacing + @section_inset.bottom
    content_size
  end
  
  def layoutAttributesForItemAtIndexPath(path)
    @item_attrs[path.item]
    UICollectionViewLayoutAttributes.layoutAttributesForCellWithIndexPath(path).tap do |attrs|
      item_height  = @delegate.collectionView(self.collectionView, layout:self, heightForItemAtIndexPath:path) if @delegate
      attrs.size   = [@item_width, item_height]
      attrs.center = @item_positions[path.item].CGPointValue
    end
  end
  
  def layoutAttributesForElementsInRect(rect)
    @item_attrs
  end
      
  
  def shouldInvalidateLayoutForBoundsChange(new_bounds); false; end
  
  private
  def shortest_column_index
    index = 0
    shortest_height = Float::MAX
    
    @column_heights.each_with_index do |obj, idx|
      height = obj.to_i
      if height < shortest_height
        shortest_height = height
        index = idx
      end
    end
    index
  end
  
  def longest_column_index
    index = 0
    longest_height = 0
    @column_heights.each_with_index do |obj, idx|
      height = obj.to_f
      if height > longest_height
        longest_height = height
        index = idx
      end
    end
    index
  end  
end