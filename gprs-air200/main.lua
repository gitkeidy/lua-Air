PROJECT = "UART"
VERSION = "1.0.0"
require"sys"
require"common" --testģ���õ���common.binstohexs�ӿ�
require"misc"
require"pm" --testģ���õ���pm.wake�ӿ�
require"wdt"
require"config"
require"nvm"
require"pincfg"
nvm.init("config.lua")

require"lcd"
require"si7021"
require"run"

sys.init(0,0)
sys.run()
