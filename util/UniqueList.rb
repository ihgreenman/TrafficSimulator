class UniqueList
  attr_reader :head, :tail, :size

  include Enumerable

  def initialize
    clear
  end

  def clear
    @head = nil
    @tail = nil
    @size = 0
    @quickLookup = nil
  end

  def canInsertItem item
    fastCanInsert item, findItemOrPrev(item)
  end

  def insertItemIfCan item
    fastInsertItemIfCan item, findItemOrPrev(item)
  end

  def insertItem item
    unless fastInsertItemIfCan item, findItemOrPrev(item)
      raise RuntimeError, "Illegal insertion: Cannot insert duplicate item #{item}"
    end

    true
  end

  def selfCheck
    item = @head
    i = 0

    while item
      if item.nextItem && item >= item.nextItem
        raise RuntimeError, "Self Check failed (ordering): #{item} #{item.nextItem}"
      end
      item = item.nextItem
      i += 1
    end

    if i != @size
        raise RuntimeError, "Self Check failed (size): #{@size} #{i}"
    end
  end

  def each
    item = @head

    while item
      yield item
      item = item.nextItem
    end
  end

  def each_reverse
    item = @tail

    while item
      yield item
      item = item.prevItem
    end
  end

  def delete item
    possible = findItemOrPrev item
    return 0 unless possible.object_id == item.object_id

    fastDeleteItem item, item.prevItem
    return 1
  end

  def findItemOrNext item
#    return nil unless @tail && position > @tail.position

    self.each do |other|
      return other if item <= other
    end

    nil
  end

  def findItemOrPrev item
    return @tail if @tail && item > @tail
    return nil unless @head

    prev = nil
    other = @quickLookup ? @quickLookup : @head

    if item > other
      while other
        break if item < other
        prev = other
        other = other.nextItem
      end
    else
      while other
        break if item >= other
        other = other.prevItem
      end

      prev = other
    end

    @quickLookup = prev
    prev
  end

private
  def fastCanInsert item, prevItem
    nextItem = prevItem ? prevItem.nextItem : @head

    return false if nextItem == item
    return false if prevItem == item
    true
  end

  def fastInsertItemIfCan item, prevItem
    return false unless fastCanInsert item, prevItem

    if prevItem
      prevItem.insertItemAfter(item)
    else
      @head = item.addHead(@head)
    end
    @tail = item unless item.nextItem

    @size += 1
    return true
  end

  def fastDeleteItem item, prevItem
    @quickLookup = nil

    if prevItem
      prevItem.deleteItemAfter
      @tail = prevItem unless prevItem.nextItem
    else
      @head = @head.deleteHead if @head
      @tail = nil unless @head
    end

    @size -= 1 if @size > 0
  end
end
