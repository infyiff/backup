local default = '{"currentShade2":[0.18039216101169587,0.18039216101169587,0.18431372940540315],"StayOpen":false,"logsEnabled":false,"aliases":[],"PluginsTable":[],"prefix":";","binds":[],"currentShade3":[0.30588236451148989,0.30588236451148989,0.30980393290519717],"WayPoints":[],"jLogsEnabled":false,"currentScroll":[0.30588236451148989,0.30588236451148989,0.30980393290519717],"keepIY":true,"eventBinds":[],"espTransparency":0.3,"currentShade1":[0.1411764770746231,0.1411764770746231,0.14509804546833039],"currentText2":[0,0,0],"currentText1":[1,1,1]}'
local filename = "IY_FE.iy"
local ran, file = pcall(readfile, filename) -- attempt to read the corrupted save
if ran then
    pcall(writefile, "backup_" .. filename, file) -- backup the corrupted save just in case
end
writefile(filename, default) -- overwrite the original
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() -- run the iy loadstring
