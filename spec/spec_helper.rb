lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'brainfuck'

RSpec.configure do |config|
  config.around(:each) do |example|
    Pry.rescue do
      err = example.run
      pending = err.is_a?(RSpec::Core::Pending::PendingExampleFixedError)
      Pry.rescued(err) if err && !pending && $stdin.tty? && $stdout.tty?
    end
  end
end
