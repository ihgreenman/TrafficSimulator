
module UniqueListItem
  include Comparable

  attr_reader :prevItem
  attr_reader :nextItem

  def addHead(item)
    @prevItem     = nil
    @nextItem     = item
    item.prevItem = self if item
    self
  end

  def deleteHead
    item = @nextItem
    item.prevItem = nil if item
    @nextItem = nil
    item
  end

  def insertItemAfter(item)
    if (defined? @nextItem) && @nextItem != nil
      @nextItem.prevItem = item
      item.nextItem      = @nextItem
    else
      item.nextItem      = nil
    end

    item.prevItem      = self
    @nextItem          = item
    1
  end

  def deleteItemAfter
    item = @nextItem
    @nextItem = item.nextItem if item
    @nextItem.prevItem = self if @nextItem
    item.prevItem = nil
    item.nextItem = nil
    1
  end

protected
  def prevItem= (item)
    @prevItem = item
  end

  def nextItem= (item)
    @nextItem = item
  end
end
