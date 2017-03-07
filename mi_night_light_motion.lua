-- Ночник на основе Xiaomi RGB Gateway
-- Если было движение и освещенность меньше заданной, то включаем подстветку
-- Если движение прекратилось или светло, то выключаем
commandArray = {}

if devicechanged['Burglar Hall'] == nil and
    devicechanged['Lux Hall'] == nil then
   return commandArray
end
--//////////////////////////////////////////////////////////////////////////////

local setLevel = 0
local miRGBName = 'Xiaomi RGB Gateway'

local lux = tonumber(otherdevices_svalues['Lux Hall']) -- текущее значение Lux
local rgbLevel = tonumber(otherdevices_svalues[miRGBName]) -- текущее значение Mi RGB level 
local burglar = otherdevices['Burglar Hall'] -- текущее значение burglar

if burglar == 'On' then -- если сработал датчик движения
    if lux < 1 then -- если датчик света меньше чем задано
	    setLevel = 5 -- устанавливаем уровень подсветки
    end	
end	

if setLevel ~= rgbLevel then
	commandArray[#commandArray+1] = {[miRGBName] = 'Set Level ' ..setLevel} -- устанавливаем новое значение Mi RGB level
	print('***** Установка значения '..miRGBName..' level : стар '..tostring(rgbLevel)..' нов '..tostring(setLevel).." *****")
end	    

return commandArray