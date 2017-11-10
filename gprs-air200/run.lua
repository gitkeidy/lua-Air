module(...,package.seeall)
require"webRequest"

local showQRCode = false
local bIsPms5003 = false
local bIsPms5003s = false
local aqi,pm25,hcho = nil

--����ID,1��Ӧuart1
--���Ҫ�޸�Ϊuart2����UART_ID��ֵΪ2����
local UART_ID = 1
--���ڶ��������ݻ�����
local rdbuf = ""


--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������runǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("run",...)
end

local function calcAQI(pNum)
     --local clow = {0,15.5,40.5,65.5,150.5,250.5,350.5}
     --local chigh = {15.4,40.4,65.4,150.4,250.4,350.4,500.4}
     --local ilow = {0,51,101,151,201,301,401}
     --local ihigh = {50,100,150,200,300,400,500}
     local ipm25 = {0,35,75,115,150,250,350,500}
     local laqi = {0,50,100,150,200,300,400,500}
     local result={"��","��","�����Ⱦ","�ж���Ⱦ","�ض���Ⱦ","������Ⱦ","����"}
     --print(table.getn(chigh))
     aqiLevel = 8
     for i = 1,table.getn(ipm25),1 do
          if(pNum<ipm25[i])then
               aqiLevel = i
               break
          end
     end
     --aqiNum = (ihigh[aqiLevel]-ilow[aqiLevel])/(chigh[aqiLevel]-clow[aqiLevel])*(pNum-clow[aqiLevel])+ilow[aqiLevel]
     aqiNum = (laqi[aqiLevel]-laqi[aqiLevel-1])/(ipm25[aqiLevel]-ipm25[aqiLevel-1])*(pNum-ipm25[aqiLevel-1])+laqi[aqiLevel-1]
     return aqiNum,result[aqiLevel-1]
end

--[[
��������parse
����  ������֡�ṹ������������
����  ��
		data������δ���������
]]
local function parse(data)
	if not data then return end	
	if((((string.byte(data,1)==0x42) and(string.byte(data,2)==0x4d)) or ((string.byte(data,1)==0x32) and(string.byte(data,2)==0x3d))) and string.byte(data,13)~=nil and string.byte(data,14)~=nil)  then
          if((string.byte(data,1)==0x32) and(string.byte(data,2)==0x3d)) then
               --Teetc.com
               pm25 = (string.byte(data,7)*256+string.byte(data,8))
          else
               pm25 = (string.byte(data,13)*256+string.byte(data,14))
               if(string.byte(data,29) ~=nil and string.byte(data,30)~=nil)then
                    if(string.byte(data,29) > 0x50 and string.byte(data,30) == 0x00)then
                         hcho = nil
                         bIsPms5003 = true
                         bIsPms5003s = false
                    else
                         bIsPms5003 = false
                         bIsPms5003s = true
                         if(lcd.getCurrentPage()~=4) then
                         	lcd.setPage(4)
                         end
                         hcho = (string.byte(data,29)*256+string.byte(data,30))/1000
                         if(hcho~=nil)then
								lcd.setText("HCHO",hcho)
						   end
                    end
               end
          end
          aqi,result = calcAQI(pm25)
					lcd.setText("pm25",pm25..result)
					lcd.setText("aqi",aqi)
					
    end
	
	rdbuf = ""
end

--[[
��������read
����  ����ȡ���ڽ��յ�������
����  ����
����ֵ����
]]
local function read()
	local data = ""
	--�ײ�core�У������յ�����ʱ��
	--������ջ�����Ϊ�գ�������жϷ�ʽ֪ͨLua�ű��յ��������ݣ�
	--������ջ�������Ϊ�գ��򲻻�֪ͨLua�ű�
	--����Lua�ű����յ��ж϶���������ʱ��ÿ�ζ�Ҫ�ѽ��ջ������е�����ȫ���������������ܱ�֤�ײ�core�е��������ж���������read�����е�while����оͱ�֤����һ��
	while true do		
		data = uart.read(UART_ID,"*l",0)
		if not data or string.len(data) == 0 then break end
		--������Ĵ�ӡ���ʱ
		--print("read",data,common.binstohexs(data))
		rdbuf = rdbuf..data	
	end
	sys.timer_start(parse,50,rdbuf)
end

--[[
��������write
����  ��ͨ�����ڷ�������
����  ��
		s��Ҫ���͵�����
����ֵ����
]]
function write(s)
	print("write",s)
	uart.write(UART_ID,s.."\r\n")
end

function statusChk()
	temp = si7021.getTemp()
	hum = si7021.getHum()
	if(temp~=nil and hum~=nil) then
		lcd.setText("temp",temp.."��")
		lcd.setText("hum",hum.."%")
	end
	lcd.displayTestDot()
end

function dataUpload()
	if(aqi~=nil)then webRequest.appendSensorValue("AQI",aqi) end
	if(pm25~=nil)then webRequest.appendSensorValue("dust",pm25) end
	if(hcho~=nil)then webRequest.appendSensorValue("hcho",hcho) end
	temp = si7021.getTemp()
	hum = si7021.getHum()
	if(temp~=nil and hum~=nil) then
		webRequest.appendSensorValue("T1",temp)
		webRequest.sendSensorValue("H1",hum)
	end
end

--����ϵͳ���ڻ���״̬���˴�ֻ��Ϊ�˲�����Ҫ�����Դ�ģ��û�еط�����pm.sleep("run")���ߣ��������͹�������״̬
--�ڿ�����Ҫ�󹦺ĵ͡�����Ŀʱ��һ��Ҫ��취��֤pm.wake("run")���ڲ���Ҫ����ʱ����pm.sleep("run")
pm.wake("run")
--ע�ᴮ�ڵ����ݽ��պ����������յ����ݺ󣬻����жϷ�ʽ������read�ӿڶ�ȡ����
sys.reguart(UART_ID,read)
--���ò��Ҵ򿪴���
uart.setup(UART_ID,9600,8,uart.PAR_NONE,uart.STOP_1)

lcd.setInfo("�豸��ʼ����")

sys.timer_loop_start(statusChk,2000)

sys.timer_loop_start(dataUpload,120000)

lcd.setPage(1)


if(nvm.get("qrCode")~=nil)then
_G.print("qrCode = "..nvm.get("qrCode"))
_G.print("qrLength = "..nvm.get("qrLength"))
else
	--get qrCode
	--sys.timer_stop(statusChk)
	
end

--pins.set(false,pincfg.PIN24)

webRequest.connect()


--qrc = ""
--qrl = 841
--lcd.qrCodeDisp(qrc,qrl)
