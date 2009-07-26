require 'pathname'
$: << (Pathname.new(__FILE__).expand_path.parent + './lib').to_s

require 'vr/vruby'
require 'vr/winconst'
require 'vr/vrhandler'
require 'Win32API'
require 'fozolifeform'


ShellExec = Win32API.new("shell32.dll", "ShellExecuteA", %w{p p p p p i}, "i")
def open_browser url
  ShellExec.call("\0", "open", url, "\0", "\0", 1)
end

frm1 = VRLocalScreen.newform
SetLayeredWindowAttributes=Win32API.new("user32","SetLayeredWindowAttributes","IIII","I")
LWA_ALPHA = 2

module WExStyle
  WS_EX_LAYERED = 0x00080000
end

frm1.extend FozolifeForm
frm1.set_widow_size(0,0,VRLocalScreen.width,VRLocalScreen.height)
frm1.create
frm1.show

VRLocalScreen.messageloop

cap = ScreenCapture.new
rect = frm1.selected

cap.capture(rect[0],rect[1],rect[2],rect[3])

conv = SimplePNG.new
png = conv.read(cap.bmp)

config = YAML.load(Pathname.new("config.yaml").expand_path.read)
@user = config["user"]
@pass = config["pass"]

fotolife = Fotolife.new(@user,@pass)
fotolife.data = png
fotolife.title = Time.now.to_i.to_s
res = fotolife.post

open_browser res

exit
