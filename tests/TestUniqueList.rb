#!/usr/bin/ruby

require 'test/unit'
require './util/UniqueList'
require './util/UniqueListItem'

class TestItem
  include UniqueListItem

  attr_accessor :id

  def initialize(id)
    @id = id
  end

  def <=> (other)
    (@id/4).to_i <=> (other.id/4).to_i
  end
end

class TestUniqueList < Test::Unit::TestCase

  def setup
    @item1 = TestItem.new(100)
    @item2 = TestItem.new(250)
    @item3 = TestItem.new(350)
    @item4 = TestItem.new(300)
    @item5 = TestItem.new(200)
    @item6 = TestItem.new(400)
    @item7 = TestItem.new(50)
    @itemTemp = TestItem.new(0)

    @items = [@item1, @item2, @item3, @item4, @item5, @item6, @item7]
  end

  def traverseList expected, test
    exp = expected.keys
    exp.sort!
    assert_equal exp.size, test.size

    test.selfCheck

    if exp.size == 0
      assert_nil test.head
      assert_nil test.tail

      test.each do |item|
        fail("each returned item from empty list")
      end

      test.each_reverse do |item|
        fail("each_reverse returned item from empty list")
      end
      return
    end

    assert_equal exp[0], test.head
    assert_equal exp[-1], test.tail

    assert_nil test.head.prevItem
    assert_nil test.tail.nextItem

    (0..exp.size - 2).each do |i|
      assert_equal exp[i].nextItem, exp[i + 1]
      assert_equal exp[i + 1].prevItem, exp[i]
    end

    i = 0
    test.each do |item|
      assert_equal exp[i], item
      assert_equal exp[i], test.findItemOrPrev(item)
      i += 1
    end

    assert_equal exp.size, i

    i = exp.size
    test.each_reverse do |item|
      i -= 1
      assert_equal exp[i], item
      assert_equal exp[i], test.findItemOrPrev(item)
    end

    assert_equal 0, i
  end

  def testBasic
    itemList = UniqueList.new
    expected = {}

    traverseList expected, itemList
    assert_nil itemList.findItemOrPrev(@itemTemp)

    @items.each do |item|
      itemList.insertItem item
      expected[item] = item
      traverseList expected, itemList

      assert_raise RuntimeError do
        itemList.insertItem item
      end

      @itemTemp.id = item.id - 25
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item.prevItem, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id + 25
      assert_equal item.nextItem, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id + 1
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)
    end

    @itemTemp.id = 425
    assert_equal @item6, itemList.findItemOrPrev(@itemTemp)

    @itemTemp.id = 225
    assert_equal @item5, itemList.findItemOrPrev(@itemTemp)

    @itemTemp.id = 25
    assert_equal nil, itemList.findItemOrPrev(@itemTemp)

    @items.reverse.each do |item|
      itemList.delete item
      expected.delete item
      traverseList expected, itemList
    end

    @items.reverse.each do |item|
      itemList.insertItem item
      expected[item] = item
      traverseList expected, itemList

      @itemTemp.id = item.id - 25
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item.prevItem, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id + 25
      assert_equal item.nextItem, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)

      @itemTemp.id = item.id + 1
      assert_equal item, itemList.findItemOrNext(@itemTemp)
      assert_equal item, itemList.findItemOrPrev(@itemTemp)
    end

    @items.each do |item|
      itemList.delete item
      expected.delete item
      traverseList expected, itemList
    end
  end

  def testSelfCheck
    itemList = UniqueList.new
    itemList.selfCheck

    itemList.insertItem @item1
    itemList.selfCheck
    @item1.id = 150
    itemList.selfCheck

    itemList.insertItem @item2
    itemList.selfCheck
    @item1.id = 200
    @item2.id = 300
    itemList.selfCheck

    assert_raise RuntimeError do
      itemList.insertItem @item4
    end

    assert_equal 2, itemList.size
    itemList.selfCheck
    @item1.id = 300
    @item2.id = 200

    assert_raise RuntimeError do
      itemList.selfCheck
    end
  end
end
