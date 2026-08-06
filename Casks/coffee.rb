cask "coffee" do
  version "1.1.0"

  # Kept as their own lines (rather than inline in the sha256 calls below)
  # so .github/workflows/release.yml can update them with a simple sed on
  # every tagged release, without needing to tell the two sha256 lines apart.
  arm_sha256   = "6111c3e0f30c5ebcd36afeb1e171b1125e3a45fedd6f337f2954e6bc3316d473"
  intel_sha256 = "234764ce342b7f9d34a1b024f7d0b855797f6e139132f977c1717d434751fb76"

  on_arm do
    url "https://github.com/mrthiti/coffee/releases/download/v#{version}/coffee-darwin-arm64"
    sha256 arm_sha256
    binary "coffee-darwin-arm64", target: "coffee"
  end

  on_intel do
    url "https://github.com/mrthiti/coffee/releases/download/v#{version}/coffee-darwin-amd64"
    sha256 intel_sha256
    binary "coffee-darwin-amd64", target: "coffee"
  end

  name "coffee"
  desc "Keep your Mac awake even with the lid closed"
  homepage "https://github.com/mrthiti/coffee"

  postflight do
    user = ENV["USER"] || Utils.safe_popen_read("id", "-un").strip
    rule = "#{user} ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n"

    Dir.mktmpdir "coffee-sudoers" do |dir|
      rule_file = "#{dir}/coffee"
      File.write(rule_file, rule)
      File.chmod(0600, rule_file)

      if system_command("/usr/sbin/visudo", args: ["-c", "-f", rule_file], print_stderr: false).success?
        ohai "Granting passwordless sudo for `pmset -a disablesleep` (you may be asked for your password)"
        system_command "/usr/bin/install", args: ["-m", "440", rule_file, "/etc/sudoers.d/coffee"], sudo: true
      else
        opoo "Generated sudoers rule failed validation — skipping passwordless sudo setup. Run `sudo coffee` instead."
      end
    end
  end

  uninstall_postflight do
    system_command "/bin/rm", args: ["-f", "/etc/sudoers.d/coffee"], sudo: true
  end

  caveats do
    <<~EOS
      coffee needs to run `pmset -a disablesleep` as root. This cask tried to
      grant your user passwordless sudo for exactly that command during install
      (you may have been prompted for your password).

      If that step was skipped or declined, plain `coffee` will only work when
      you already have a cached sudo credential — otherwise run `sudo coffee`
      instead, or add the sudoers rule yourself (see README).
    EOS
  end
end
