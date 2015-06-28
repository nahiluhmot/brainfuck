module Brainfuck
  # This class executes the commands generated by the rest of the upstream
  # pipeline.
  class VirtualMachine
    # Raised when the memory cursor goes beyond zero.
    MemoryOutOfBounds = Class.new(StandardError)

    # Raised when an invalid command is passed to the VM.
    InvalidCommand = Class.new(StandardError)

    # Raised when the VM is given more commands to execute while it is already
    # executing a set of commands.
    ConcurrentExecution = Class.new(StandardError)

    # The initial size of the memory.
    INITIAL_MEMORY_SIZE = 32

    # The maximum amount that memory may be increased at once.
    MAX_ALLOCATION = 1_024

    # Instantiate a new VM.
    #
    # @param eof [Integer] what to return when EOF is reached.
    # @param input [IO] input stream.
    # @param output [IO] output stream.
    def initialize(input, output, eof)
      @input = input
      @output = output
      @eof = eof
    end

    # Load the commands into the VM.
    #
    # @param commands [Array<Object>] commands to execute.
    # @raise [ConcurrentExecution] when the VM is already executing commands.
    def load!(commands)
      fail ConcurrentExecution if @executing
      @executing = true
      @program_counter = 0
      @cursor = 0
      @commands = commands
      @memory = Array.new(INITIAL_MEMORY_SIZE, 0)
      nil
    end

    # Execute an Array commands.
    #
    # @raise [InvalidCommand] when an invalid command is passed the VM.
    # @raise [MemoryOutOfBounds] when the VM's memory cursor goes below zero.
    # @return [nil]
    def execute!
      until @program_counter >= @commands.length
        command, arg = @commands[@program_counter]
        send(command, arg)
      end
    rescue NoMethodError => ex
      raise InvalidCommand, ex
    ensure
      @executing = false
    end

    # Inspect the state of the VM.
    #
    # @return [Hash<Symbol, Integer>] representing the VM state.
    def state
      {
        executing: @executing,
        program_counter: @program_counter,
        cursor: @cursor,
        memory: @memory,
        current_value: @memory[@cursor]
      }
    end

    private

    def change_value(n)
      @program_counter += 1
      @memory[@cursor] += n
    end

    def change_pointer(n)
      @program_counter += 1
      @cursor += n
      fail MemoryOutOfBounds if @cursor < 0
      reallocate! if @cursor >= @memory.length
    end

    def get(n)
      @program_counter += 1
      n.times { @memory[@cursor] = @input.eof? ? @eof : @input.getc.ord }
    end

    def put(n)
      @program_counter += 1
      @output.write(@memory[@cursor].chr * n)
    end

    def branch_if_zero(n)
      if @memory[@cursor].zero?
        @program_counter += n
      else
        @program_counter += 1
      end
    end

    def branch_not_zero(n)
      if @memory[@cursor].zero?
        @program_counter += 1
      else
        @program_counter += n
      end
    end

    def reallocate!
      while @cursor >= @memory.length
        size = MAX_ALLOCATION > @memory.length ? MAX_ALLOCATION : @memory.length
        @memory += Array.new(size, 0)
      end
    end
  end
end
