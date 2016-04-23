#require 'win32/registry'

#Win32::Registry::HKEY_CLASSES_ROOT.create('Directory\shell\MaloWIMDB\command') do |reg|
#  file = "\"" + Dir.pwd.gsub('/', '\\\\') + "\\run.bat\" \"%1\""
#  reg.write(nil, Win32::Registry::REG_SZ, file)
#end

File.open("add_reg.reg", File::WRONLY | File::CREAT | File::TRUNC) do |f|
	f.flock(File::LOCK_EX)
	f.puts("Windows Registry Editor Version 5.00")
	f.puts("")
	f.puts("[HKEY_CLASSES_ROOT\\Directory\\shell\\MaloWIMDB\\command]")
	f.puts("@=\"\\\"" + Dir.pwd.gsub('/', '\\\\\\') + "\\\\run.bat\\\" \\\"%1\\\"\"")
	f.flush
end