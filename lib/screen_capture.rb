require "Win32API"
class ScreenCapture
  GetDesktopWindow = Win32API.new("user32", "GetDesktopWindow",nil, 'n')
  GetDC = Win32API.new("user32", "GetDC", ['n'], 'n')
  BitBlt = Win32API.new("GDI32", 'BitBlt', ['n']* 9, 'n')
  GetClientRect = Win32API.new("user32", 'GetClientRect', ['n','p'], 'n' )
  CreateCompatibleDC = Win32API.new("GDI32", "CreateCompatibleDC", ['n'], 'n')
  CreateCompatibleBitmap = Win32API.new("GDI32", "CreateCompatibleBitmap",['n']*3, 'n')
  SelectObject = Win32API.new("GDI32","SelectObject",['n']*2, 'n')
  GetDIBits = Win32API.new("GDI32","GetDIBits",['n','n','n','n','p','p','n'],'n')
  ReleaseDC = Win32API.new("user32","ReleaseDC",['n','n'],'i')
  DeleteObject = Win32API.new("gdi32","DeleteObject",['n'],'i')

  SRCCOPY = 0x00CC0020

  BITMAPFILEHEADER= [0,0,0,0,0].pack('slssl')
  BITMAPINFOHEADER= [0,0,0,0,0,0,0,0,0,0,0].pack('l3s2l6')

  DIB_RGB_COLORS = 0
  def capture(x=0, y=0, xw=nil, yw=nil)

    hwnd = GetDesktopWindow.call
    hdc = GetDC.call hwnd

    lpRect = [0, 0, 0, 0].pack("l4")
    GetClientRect.call(hwnd, lpRect)
    lpRect = lpRect.unpack("l4")
    dwWidth = xw || lpRect[2]
    dwHeight = yw || lpRect[3]
    bitmapinfo = [BITMAPINFOHEADER.length,
                dwWidth,
                dwHeight,
                1,
                24,
                0,
                0,
                0,
                0,
                0,
                0].pack('l3s2l6')

    hBMP = CreateCompatibleBitmap.call hdc, dwWidth, dwHeight

    hdcMem = CreateCompatibleDC.call hdc 

    hOld = SelectObject.call hdcMem, hBMP

    BitBlt.call hdcMem, 0, 0, dwWidth, dwHeight, hdc, x, y, SRCCOPY
    hBMP2 = SelectObject.call hdcMem, hOld

    if (dwWidth*3) % 4 == 0
      dwLength=dwWidth*3
    else
      dwLength=dwWidth*3 + (4-(dwWidth*3) % 4)
    end
    dwFSize=BITMAPFILEHEADER.length+BITMAPINFOHEADER.length+dwLength*dwHeight
    bitSize=dwLength*dwHeight
    pixel=([0]*bitSize).pack('c*')
    line = GetDIBits.call(hdc, hBMP, 0, dwHeight, pixel, bitmapinfo, DIB_RGB_COLORS)

    ReleaseDC.call hwnd, hdc
    DeleteObject.call hBMP
    DeleteObject.call hdcMem

    header_length = BITMAPFILEHEADER.length + bitmapinfo.length
    bitmap_file_header = ['BM',dwFSize,0,0,header_length].pack('a2lssl')
    @bitmap = bitmap_file_header + bitmapinfo + pixel
  end

  def write(file_name)
    File.open(file_name,'wb'){|io|
      io.write(@bitmap)
    }
  end
  
  def bmp
    @bitmap
  end
end
