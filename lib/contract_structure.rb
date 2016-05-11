require 'pp'
require 'optparse'
require 'tmpdir'

class ContractStructure
  def initialize args
    parse_args args

    do_work
  end

  def parse_args args
    @opts = {
      :opt => true,
    }
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [-options] args"
      opts.on("-o opt", "--option") do |o|
        @opts[:opt] = o
      end
    end.parse! args
    @args = args
  end

  def do_work
    @relation = {}
    File.read(@args[0]).split("\n").each do |line|
      if line =~ /^\s*contract\s+(\S+)/
        parse_contract_line line
      end
    end
    pp @relation
  end

  def parse_contract_line line
    if line =~ /^\s*contract\s+(\S+)\s+is\s+(\S+)/
      if @relation[$2].nil?
        @relation[$2] = [$1]
      else
        @relation[$2] << $1
      end
    elsif line =~ /^\s*contract\s+(\S+)/
      @relation[$1] = [] if @relation[$1].nil?
    end
  end
end

if $0 == __FILE__
  ContractStructure.new ARGV
end
