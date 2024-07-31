module SafeShell
  def self.execute(command, *args)
    output = ''
    if RUBY_PLATFORM == 'java'
      require 'spoon'
      require 'stringio'
      old_stdout = $stdout
      $stdout = StringIO.new
      file_actions = Spoon::FileActions.new
      spawn_attr = Spoon::SpawnAttributes.new
      full_args = [command, *args]
      pid = Spoon.posix_spawnp(command, file_actions, spawn_attr, full_args)
      Process.waitpid(pid)
      output = $stdout.string
      $stdout = old_stdout
    else
      read_end, write_end = IO.pipe
      pid = fork do
        read_end.close
        STDOUT.reopen(write_end)
        STDERR.reopen(write_end)
        exec(command, *args)
      end
      write_end.close
      output = read_end.read
      Process.waitpid(pid)
      read_end.close
    end
    output
  end

  def self.execute?(*args)
    execute(*args)
    $?.success?
  end
end
