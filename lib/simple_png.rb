require 'zlib'
class SimplePNG
  class ReadableString < String
    def initialize(arg)
      super(arg)
      @read_point = 0
    end
    def read(length)
      readed = self[@read_point,length]
      @read_point += length
      return nil if readed.size == 0 
      return readed
    end
    def binmode
      self
    end
    def close
      self
    end
  end
  
  BITMAPFILEHEADER = 14
  def initialize
  end
  
  def read_bmp(bmp_string)
    @bmp_io = ReadableString.new(bmp_string)
    @bit_map_file_header = @bmp_io.read(BITMAPFILEHEADER)
  end

  def open_bmp(file_name)
    @file_name = file_name
    @bmp_io = File.open(file_name,'rb')
    @bmp_io.binmode
    @bit_map_file_header = @bmp_io.read(BITMAPFILEHEADER)
  end

  def parse_header
    @file_type = @bit_map_file_header[0,2]
    @bit_map_file_header[2,4]
    @file_size = @bit_map_file_header[2,4].unpack('V')[0]
    @data_offset = @bit_map_file_header[10,4].unpack('V')[0]
  end

  def parse_info
    @info_size = @bmp_io.read(4).unpack('l!')[0]
    @info_size = @info_size
    @infodata = @bmp_io.read(@info_size - 4)
    
    raise "Not supported type bmp" if @info_size != 40
    
    @width = @infodata.slice!(0,4).unpack('l!')[0]
    @height = @infodata.slice!(0,4).unpack('l!')[0]
    @planes = @infodata.slice!(0,2).unpack('v')[0]
    @bit_count = @infodata.slice!(0,2).unpack('v')[0]
    @compression = @infodata.slice!(0,4).unpack('V')[0]
    @size_image = @infodata.slice!(0,4).unpack('V')[0]
    @x_pels_per_meter = @infodata.slice!(0,4).unpack('l!')[0]
    @y_pels_per_meter = @infodata.slice!(0,4).unpack('l!')[0]
    @clr_used = @infodata.slice!(0,4).unpack('V')[0]
    @clr_important = @infodata.slice!(0,4).unpack('V')[0]
  end
  
  def parse_data
    readed_length = @info_size + BITMAPFILEHEADER
    if readed_length != @data_offset
      to_read = @data_offset - readed_length
      @bmp_io.read(to_read)
    end
    line = (@width * @bit_count) / 8
    if line % 4 != 0
      line = ((line / 4) + 1 ) * 4
    end
    z = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION)
    @data = ''
    ordered = []
    while line_data = @bmp_io.read(line)
      tmp = ''
      @width.times{|i|
        b = line_data[0+i*3]
        g = line_data[1+i*3]
        r = line_data[2+i*3]
        tmp << [r, g, b].pack('c3')
      }
      ordered.unshift(tmp)
    end
    ordered.each do |tmp_bytes|
      line_bytes = [0].pack('c') + tmp_bytes
      @data << z.deflate(line_bytes)
    end
    @data << z.finish
    z.close
    @bmp_io.close
  end

  def make_header
    @sig = "\x89PNG\r\n\x1a\n"
    @IHDR = ''
    @IHDR << [@width].pack('N')
    @IHDR << [@height].pack('N')
    @IHDR << [@bit_count / 3].pack('c')
    @IHDR << [2].pack('c')
    @IHDR << [0].pack('c')
    @IHDR << [0].pack('c')
    @IHDR << [0].pack('c')
    datalength = [@IHDR.size].pack('N')
    chunkname = ['IHDR'].pack('A*')
    data = @IHDR
    crc = [Zlib.crc32(chunkname + data)].pack('N')
    @IHDR = datalength + chunkname + data + crc
  end

  def make_idat
    @IDAT = ''
    datalength = [@data.size].pack('N')
    chunkname = ['IDAT'].pack('A*')
    data = @data
    crc = [Zlib.crc32(chunkname + data)].pack('N')
    @IDAT = datalength + chunkname + data + crc
  end

  def make_iend
    @IEND = ''
    datalength = [0].pack('N')
    chunkname = ['IEND'].pack('A*')
    data = ''
    crc = [Zlib.crc32(chunkname + data)].pack('N')
    @IEND = datalength + chunkname + data + crc
  end

  def make_png
    parse_header
    parse_info
    parse_data
    make_header
    make_idat
    make_iend
    @png = @sig + @IHDR + @IDAT +@IEND
  end

  def write
    base = File.basename(@file_name,".*")
    dir = File.dirname(@file_name)
    png_file = dir + '/' + base + '.png'
    File.open(png_file,'wb'){|io|
      io.write(@png)
    }
  end

  def open(filename)
    open_bmp(filename)
    make_png
  end

  def read(string)
    read_bmp(string)
    make_png
  end
end
