require 'screen_capture'
require 'fotolife'
require 'simple_png'
require 'yaml'
require 'Win32API'

module FozolifeForm 
  include VRMouseFeasible
  include VRDrawable
  BLUE=RGB(0, 0, 0xff)
  @x = 0
  @y = 0
  @xw = 0
  @yw = 0
  @lbuttondowned = false
  @selected = []
  attr_reader :selected

  def construct
    #self.move 0,0,1920,1080
    self.move *@window_size
    self.style = WStyle::WS_VISIBLE | WStyle::WS_POPUP
    self.exstyle = WExStyle::WS_EX_LAYERED
    set_alpha(self, 100)
    @rect = []
    @lbuttondowned = false
  end
  
  def self_lbuttondown (shift, x, y)
    @rect << x
    @rect << y
    @lbuttondowned = true
  end

  def self_mousemove (shift, x, y)
    if (@lbuttondowned)
      @x = @rect[0]
      @y = @rect[1]
      @xw = x
      @yw = y
      refresh
    end
  end

  def self_lbuttonup (shift, x, y)
    @lbuttondowned = false
    set_alpha(self, 0)
    refresh
    @rect << x
    @rect << y

    x = @rect[0] < @rect[2] ? @rect[0] : @rect[2]
    y = @rect[1] < @rect[3] ? @rect[1] : @rect[3]
    x2 = @rect[0] < @rect[2] ? @rect[2] : @rect[0]
    y2 = @rect[1] < @rect[3] ? @rect[3] : @rect[1]
    xw = x2 - x 
    yw = y2 - y

    @selected = [x, y, xw, yw]

    @rect = []
    close
  end
  
  def self_paint
    if @lbuttondowned
      setPen(BLUE)
      setBrush(BLUE)
      fillRect(@x, @y, @xw, @yw)
    end
  end

  def set_widow_size (x, y, wx, wy)
    @window_size = [x, y, wx, wy]
  end

  def set_alpha (target, alpha)
    SetLayeredWindowAttributes.call(target.hWnd, 0, alpha, LWA_ALPHA)
  end
end
