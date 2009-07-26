require 'pathname'
$: << (Pathname.new(__FILE__).expand_path.parent + './lib').to_s

require 'vr/vruby'
require 'vr/winconst'
require 'vr/vrhandler'
require 'Win32API'
require 'fozolifeform'


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

exit
