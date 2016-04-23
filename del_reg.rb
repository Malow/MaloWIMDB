#require 'win32/registry'

#Win32::Registry::HKEY_CLASSES_ROOT.delete_key('Directory\shell\MaloWIMDB', true)

File.open("del_reg.reg", File::WRONLY | File::CREAT | File::TRUNC) do |f|
	f.flock(File::LOCK_EX)
	f.puts("Windows Registry Editor Version 5.00")
	f.puts("")
	f.puts("[-HKEY_CLASSES_ROOT\\Directory\\shell\\MaloWIMDB]")
	f.flush
end