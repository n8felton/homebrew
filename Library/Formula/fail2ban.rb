require "formula"

class Fail2ban < Formula
  homepage "http://www.fail2ban.org/"
  url "https://github.com/fail2ban/fail2ban/archive/0.9.1.tar.gz"
  sha1 "4214a0e291f29158d44dccc659c81cbc97e2f42e"

  bottle do
    sha1 "ab90e39f9669b929dd4ec43b9f736a1ab1cac652" => :mavericks
    sha1 "3b2c563f7316ed9c485744e24ec6abc3bb242040" => :mountain_lion
    sha1 "0c91986b55c0d35497ef0d4c42d992c9958c577e" => :lion
  end

  def install
    rm "setup.cfg"
    inreplace "setup.py" do |s|
      s.gsub! /\/etc/, etc
      s.gsub! /\/var/, var
    end

    # Replace hardcoded paths
    inreplace "bin/fail2ban-client", "/etc", etc

    inreplace "bin/fail2ban-server", "/var/run", (var/"run")

    inreplace "config/fail2ban.conf", "/var/run", (var/"run")
    inreplace "config/fail2ban.conf", "/var/lib", (var/"lib")

    inreplace "setup.py", "/usr/share/doc/fail2ban", (libexec/"doc")
    
    man.mkpath
    man1.install "man/fail2ban-client.1", "man/fail2ban-regex.1", "man/fail2ban-server.1", "man/fail2ban.1"
    man5.install "man/jail.conf.5"

    ENV.prepend_create_path "PYTHONPATH", libexec/"lib/python2.7/site-packages"
    system "python", *Language::Python.setup_install_args(libexec)
    bin.install Dir[libexec/"bin/*"]
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  plist_options :startup => true

  def plist; <<-EOS.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/fail2ban-client</string>
          <string>-x</string>
          <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
      </dict>
      </plist>
    EOS
  end

  def caveats
    <<-EOS.undent
      Before using Fail2Ban for the first time you should edit jail
      configuration and enable the jails that you want to use, for instance
      ssh-ipfw. Also make sure that they point to the correct configuration
      path. I.e. on Mountain Lion the sshd logfile should point to
      /var/log/system.log.

        * #{etc}/fail2ban/jail.conf

      The Fail2Ban wiki has two pages with instructions for MacOS X Server that
      describes how to set up the Jails for the standard MacOS X Server
      services for the respective releases.

        10.4: http://www.fail2ban.org/wiki/index.php/HOWTO_Mac_OS_X_Server_(10.4)
        10.5: http://www.fail2ban.org/wiki/index.php/HOWTO_Mac_OS_X_Server_(10.5)
    EOS
  end
end
