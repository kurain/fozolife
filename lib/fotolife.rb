require "rubygems"
require "atomutil"
require "yaml"
require "pathname"

class Fotolife
  attr_accessor :data, :title
  POST_URI = "http://f.hatena.ne.jp/atom/post"
  def initialize(user,password,opt={})
    @user = user
    @password = password
    @tool_name = opt[:tool_name] || opt['tool_name'] || 'fotolife.rb'
    @post_uri = opt[:uri] || opt['uri'] || POST_URI
  end

  def open(filename)
    @data = File.open(filename,'rb').binmode.read
    @title = Pathname.new(filename).basename.to_s
    return self
  end

  def post(data=@data,opt={})
    @data = data
    raise 'no image' unless @data
    entry = Atom::Entry.new({
                              :title => @title,
                              :updated => Time.now,
                              :content => Atom::Content.new { |c|
                                c.body = [@data].pack('m').split.join
                                c.type = "image/png"
                                c.set_attr(:mode, "base64")
                              },
                              :generator => @tool_name,
                            })
    client = Atompub::Client.new({
                                   :auth => Atompub::Auth::Wsse.new(:username => @user, :password => @password)
                                 })
    edit_url = client.create_entry(@post_uri, entry, @title)
    foto_num = edit_url.split('/')[-1]
    return "http://f.hatena.ne.jp/#{@user}/#{foto_num}"
  end
end
