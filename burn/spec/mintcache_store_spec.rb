require File.dirname(__FILE__) + '/spec_helper'
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb-cache', 'cache_stores', 'mintcache_store')


describe "memcached base" do
  before :all do
    Merb::Cache.setup(:mintcache, :mintcache, :host => "127.0.0.1:11211" )
    @store = Merb::Cache[:mintcache]
  end
  
  after :all do
    Merb::Cache.active_stores.delete(:mintcache)
  end
  
  it "should respond to connect" do
    @store.private_methods.should include("connect")
  end
  
  it "should respond to put" do
    @store.public_methods.should include("put")
  end
  
  it "should respond to get" do
    @store.public_methods.should include("get")
  end
  
  it "should respond to expire" do
    @store.public_methods.should include("expire!")
  end
  
  it "should store a key" do
    @store.put('key', "stored_data", 10)
  end
  
  it "should get a key" do
    @store.get('key').should eql("stored_data")
  end
  
  it "should know if theres a cache" do
    @store.cached?('key').should be_true
  end
  
  it "should expire a key" do
    @store.get('key').should eql "stored_data"
    @store.expire!('key')
    @store.cached?('key').should be_false
  end
  
  it "should know when there isn't a cache" do
    @store.cached?("key").should be_false
  end
end

describe "mintache store avoiding the dogpile effect" do
  before :all do
    @store = Merb::Cache::MintcachedStore.new({:host => "127.0.0.1:11211"})
  end
  
  it "should store a second key to keep check of the time" do
    @store.put("key", "data", 10)
    @store.get("key_validity").should_not be_nil
  end
  
  it "should store the validity key for double the amount of time of the initial expiry" do
    expiry = Time.now + 60
    @store.put("expiry_key_spec", "regular cache data", 60)
    @store.get("expiry_key_spec_validity").to_s.should eql expiry.to_s
  end
  
  it "should store a third key to keep the data for a longer expiry time" do
    @store.put("key", "data", 10)
    @store.get("key_data").should_not be_nil
  end
  
  it "should return a cache miss when the second level cache is used" do
    @store.put("short_key", "data", 1)
    sleep 1
    @store.cached?("short_key").should be_false
  end
  
  it "should store a backup key to avoid cache misses" do
    @store.put("short_key", "data", 1)
    sleep 1
    @store.get("short_key").should be_nil
    @store.get("short_key").should eql "data"
  end
  
  it "should expire all additional keys when expire is called" do
    @store.put("key", "data", 1)
    @store.expire!("key")
    @store.get("key").should be_nil
    @store.get("key_validity").should be_nil
    @store.get("key_data").should be_nil
  end
end