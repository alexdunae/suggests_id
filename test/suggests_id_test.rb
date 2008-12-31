require File.dirname(__FILE__) + '/test_helper'

require File.join(File.dirname(__FILE__), 'fixtures/page')

class SuggestsIDTest < Test::Unit::TestCase
  fixtures :pages

  def setup
    @allowable_characters = Regexp.new('^[A-Za-z0-9_-]+$')
  end

  def test_create_from_string
    i = Page.suggest_id('My new title')
    assert_equal 'mynewtitle', i
  end

  def test_create_from_array
    i = Page.suggest_id(['John', 'H.', 'Smith', 'Jr.'])
    assert_equal 'johnhsmithjr', i
  end
  
  def test_create_with_disposable_words
    i = Page.suggest_id('My new school title')
    assert_equal 'mynewtitle', i
  end

  def test_creating_duplicates
    t = 'My page title'
    i = Page.suggest_id(t)
    p1 = create_page(:title => t, :url => i)
    
    assert_not_equal i, Page.suggest_id(t)
  end

  def test_iteration
    t = 'Title'
    i = Page.suggest_id(t)
    assert_equal 'title', i

    p1 = create_page(:title => t, :url => i)    
    assert_equal 'title-0000', Page.suggest_id(t)

    p2 = create_page(:title => t, :url => 'title-0000')
    assert_equal 'title-0001', Page.suggest_id(t)

  end

  def test_requires_string_or_array
    assert_raise(ArgumentError) do
      i = Page.suggest_id({'one' => 'two'})
    end
  end

  def test_wacky_characters
    ['Title', 'Title and some spaces', 'Title-with-dashes',
     'Title-with\'-$#)(*%symbols', '/urltitle/', 
     'calculé en française','123'
    ].each do |t|
      i = Page.suggest_id(t)
      assert_match @allowable_characters, i
    end
  end

private
  def create_page(options = {})
    Page.create({
      :title => 'My new page'
    }.merge(options))
  end
end
