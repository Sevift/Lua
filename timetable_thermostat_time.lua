commandArray = {}

function fillTabTemperature()

	local tempDay     = tonumber(otherdevices_svalues['Temperature Day']) -- текущее значение темп для дня

	local time_Wake              = 530  -- время подъема 
	local time_Work              = 730  -- начало рабочее 
	local time_Relax             = 2030 -- начало укладывания              
	local time_Sleep             = 2100 -- начало сна         

	local time_Wake_Weekend      = 600  -- время подъема в выходные 
	local time_Relax_Weekend     = 2130 -- начало укладывания  
	local time_Sleep_Weekend     = 2200 -- время отбоя в выходные 

	local interval = {}

	-- зал 
	interval[#interval+1] = {room = 1, day = 1, timeFrom = time_Wake,           timeTo = time_Sleep,            temp = tempDay} 

	interval[#interval+1] = {room = 1, day = 5, timeFrom = time_Wake,           timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 1, day = 6, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 1, day = 7, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep,            temp = tempDay} 

	-- спальня
	interval[#interval+1] = {room = 2, day = 1, timeFrom = time_Wake,           timeTo = time_Work,             temp = tempDay} 
	interval[#interval+1] = {room = 2, day = 1, timeFrom = time_Relax,          timeTo = time_Sleep,            temp = tempDay} 

	interval[#interval+1] = {room = 2, day = 5, timeFrom = time_Wake,           timeTo = time_Work,             temp = tempDay} 
	interval[#interval+1] = {room = 2, day = 5, timeFrom = time_Relax_Weekend,  timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 2, day = 6, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 2, day = 7, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep,            temp = tempDay} 

	-- детская
	time_Relax = 1130
	interval[#interval+1] = {room = 3, day = 1, timeFrom = time_Wake,           timeTo = time_Work,             temp = tempDay} 
	interval[#interval+1] = {room = 3, day = 1, timeFrom = time_Relax,          timeTo = time_Sleep,            temp = tempDay} 

	interval[#interval+1] = {room = 3, day = 5, timeFrom = time_Wake,           timeTo = time_Work,             temp = tempDay} 
	interval[#interval+1] = {room = 3, day = 5, timeFrom = time_Relax,          timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 3, day = 6, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep_Weekend,    temp = tempDay} 

	interval[#interval+1] = {room = 3, day = 7, timeFrom = time_Wake_Weekend,   timeTo = time_Sleep,            temp = tempDay} 
	return interval

end

function NumberOfTheDay() -- номер дня
	local day = tonumber(os.date("%w"))
	if day == 0 then -- lua считает 0-6 вос-суб
		day = 7
	end	
    return day
end

function HourMinNow() -- текущие час и мин
	local hour = os.date("%H")
	local min  = os.date("%M")
	local hourMin = tonumber(hour..min)

	return hourMin
end

function getTemperature(thermostatName)
	
	local setTemp = tonumber(otherdevices_svalues['Temperature Night'])  -- текущее значение темп, которую установить по умолчанию 
	local interval = fillTabTemperature() -- получим таблицу комнат, интервалов и темеператур

	for i in pairs(interval) do
			
		local room     = 'Thermostat '..rooms[interval[i]['room']]
		local day      = interval[i]['day']
		local timeFrom = interval[i]['timeFrom']
		local timeTo   = interval[i]['timeTo']
		local temp     = interval[i]['temp']

		local numberOfTheDay = NumberOfTheDay()
		if 5 - numberOfTheDay > 0 then -- если номер дня 1,2,3,4 то 1
			numberOfTheDay = 1
		end	

		if room == thermostatName and day == numberOfTheDay then	

			if HourMinNow() > timeFrom and HourMinNow() <= timeTo then
				setTemp = temp	
			end		
		end	
	end	

	return setTemp

end

rooms = {'Hall', 'Bedroom', 'Children'}

for room in pairs(rooms) do 

	local roomName       = rooms[room]
	local thermostatName = 'Thermostat '..roomName -- имя термостата

	local tempTs = tonumber(otherdevices_svalues[thermostatName]) -- текущее значение температуры вирт термостата
	local setTemp  = getTemperature(thermostatName)               -- температура которую установить

	if setTemp ~= nil and tempTs ~= setTemp and otherdevices['Auto Thermostat '..roomName] == 'On' then

		commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[thermostatName]..'|0|'..tostring(setTemp)} -- устанавливаем новое значение термостата

		print('***** Установка значения термостата '..thermostatName..': стар '..tostring(tempTs)..' нов '..tostring(setTemp).." *****")

	end	
end

return commandArray
