-- Добавляем виртуальные термостаты - в них будем устанавливать нужную температуру в комнатах
-- В звисимостти от установленной температуры и внешних датчиков температуры будем управлять реальными термостатами

commandArray = {}

if devicechanged['TempHum Hall_Temperature'] == nil and
    devicechanged['TempHum Bedroom_Temperature'] == nil and
    devicechanged['TempHum Children_Temperature'] == nil then
    return commandArray -- если это не внешние датчики температуры, то ни чего не делаем 
end
--//////////////////////////////////////////////////////////////////////////////

function Round(num, idp) -- округление
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

minTemp = 18 -- максимальная температура термостата
maxTemp = 35 -- минимальная температура термостата
delta = 0.2 -- разница температур вниз при которой ни чего не делаем
 
rooms = {'Hall', 'Hall Tele', 'Bedroom', 'Children'} -- комнаты

for room in pairs(rooms) do 

	local roomName       = rooms[room] --- имя комнаты
	local comfortName    = 'Comfort setpoint '..roomName -- имя режима Comfort реального термостата
	roomName = roomName:gsub(' Tele', '') -- Вырезаем из имени термостата 'Tele' чтобы скрипт думал, что это один термостат так как термостаты Hall и Hall Tele находятся в одной комнате, а значит управляем ими одинаково

	local comfort  = Round(tonumber(otherdevices_svalues[comfortName]), 1)  -- текущее значение Comfort (температуры режима Comfort)
	local tempNeed = Round(tonumber(otherdevices_svalues['Thermostat '..roomName]), 1) -- текущее значение температуры вирт термостата
	local tempHum  = Round(tonumber(otherdevices_temperature['TempHum '..roomName]), 1) -- текущее значение tempHum (внешний датчик температуры)
	
	local difference = tempNeed - tempHum -- разница между нужной температуры и внешнего датчика температуры
	if difference > 0 and difference <= delta then 
	    difference = 0   
	end    

	local setComfort = Round(difference * 10 + tempNeed, 1) -- на каждую разницу в 0.1 градус меняем Comfort на 1 градус

	if setComfort < minTemp then
		setComfort = minTemp
	end
	
	if setComfort > maxTemp then
		setComfort = maxTemp
	end	
	
	--print(comfortName..' comfort= '..comfort..' setComfort= '.. setComfort..' условие '..tostring(setComfort == comfort))
    --print('tempHum: '..tempHum..' tempNeed ' ..tempNeed..' difference '..difference)

	if setComfort ~= comfort then

		commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[comfortName]..'|0|'..tostring(setComfort)} -- устанавливаем новое значение Comfort
		print('***** Установка значения Comfort '..comfortName..': стар '..tostring(comfort)..' нов '..tostring(setComfort).." *****")

	end	

end

return commandArray