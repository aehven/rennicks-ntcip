Gem::Specification.new do |s|
  s.name = %q{ntcipAccess}
  s.authors = %q{Doug Harbert}
  s.email = %q{doug@harbert.org}
  s.description = %q{NTCIP access code}
  s.homepage = %q{}
  s.version = "0.0.3"
  s.date = %q{2018-08-24}
  s.summary = %q{NTCIP Access}
  s.files = [
    "lib/ntcipAccess.rb",
    "lib/ntcipEnums.rb",
    "lib/ntcipOIDList.rb",
    "lib/snmpAccess.rb",
    "lib/bmp.rb",
    "lib/mibs/NTCIP-1201-MIB.yaml",
    "lib/mibs/NTCIP-1203-MIB.yaml",
    "lib/mibs/NTCIP1204-2005-MIB.yaml",
    "lib/mibs/NTCIP8004-A-2004.yaml"
  ]
  s.require_paths = ["lib"]
end
