#--
# This file is automatically generated. Do not modify it.
# Generated by: oedipus_lex version 2.1.0.
# Source: lib/oedipus_lex.rex
#++

class OedipusLex
  require 'strscan'

  ST  = /(?:(:\S+|\w+\??))/
  RE  = /(\/(?:\\.|[^\/])+\/[ion]?)/
  ACT = /(\{.*|:?\w+)/

  class ScanError < StandardError ; end

  attr_accessor :lineno
  attr_accessor :filename
  attr_accessor :ss
  attr_accessor :state

  alias :match :ss

  def matches
    m = (1..9).map { |i| ss[i] }
    m.pop until m[-1] or m.empty?
    m
  end

  def action
    yield
  end

  def do_parse
    while token = next_token do
      type, *vals = token

      send "lex_#{type}", *vals
    end
  end

  def scanner_class
    StringScanner
  end unless instance_methods(false).map(&:to_s).include?("scanner_class")

  def parse str
    self.ss     = scanner_class.new str
    self.lineno = 1
    self.state  ||= nil

    do_parse
  end

  def parse_file path
    self.filename = path
    open path do |f|
      parse f.read
    end
  end

  def next_token
    self.lineno += 1 if ss.peek(1) == "\n"

    token = nil

    until ss.eos? or token do
      token =
        case state
        when nil, :option, :inner, :start, :macro, :rule, :group then
          case
          when text = ss.scan(/options?.*/) then
            [:state, :option]
          when text = ss.scan(/inner.*/) then
            [:state, :inner]
          when text = ss.scan(/macros?.*/) then
            [:state, :macro]
          when text = ss.scan(/rules?.*/) then
            [:state, :rule]
          when text = ss.scan(/start.*/) then
            [:state, :start]
          when text = ss.scan(/end/) then
            [:state, :END]
          when text = ss.scan(/\A((?:.|\n)*)class ([\w:]+.*)/) then
            action { [:class, *matches] }
          when text = ss.scan(/\n+/) then
            # do nothing
          when text = ss.scan(/\s*(\#.*)/) then
            action { [:comment, text] }
          when (state == :option) && (text = ss.scan(/\s+/)) then
            # do nothing
          when (state == :option) && (text = ss.scan(/stub/i)) then
            action { [:option, text] }
          when (state == :option) && (text = ss.scan(/debug/i)) then
            action { [:option, text] }
          when (state == :option) && (text = ss.scan(/do_parse/i)) then
            action { [:option, text] }
          when (state == :option) && (text = ss.scan(/lineno/i)) then
            action { [:option, text] }
          when (state == :inner) && (text = ss.scan(/.*/)) then
            action { [:inner, text] }
          when (state == :start) && (text = ss.scan(/.*/)) then
            action { [:start, text] }
          when (state == :macro) && (text = ss.scan(/\s+(\w+)\s+#{RE}/o)) then
            action { [:macro, *matches] }
          when (state == :rule) && (text = ss.scan(/\s*#{ST}?[\ \t]*#{RE}[\ \t]*#{ACT}?/o)) then
            action { [:rule, *matches] }
          when (state == :rule) && (text = ss.scan(/\s*:[\ \t]*#{RE}/o)) then
            action { [:grouphead, *matches] }
          when (state == :group) && (text = ss.scan(/\s*:[\ \t]*#{RE}/o)) then
            action { [:grouphead, *matches] }
          when (state == :group) && (text = ss.scan(/\s*\|\s*#{ST}?[\ \t]*#{RE}[\ \t]*#{ACT}?/o)) then
            action { [:group, *matches] }
          when (state == :group) && (text = ss.scan(/\s*#{ST}?[\ \t]*#{RE}[\ \t]*#{ACT}?/o)) then
            action { [:groupend, *matches] }
          else
            text = ss.string[ss.pos .. -1]
            raise ScanError, "can not match (#{state.inspect}): '#{text}'"
          end
        when :END then
          case
          when text = ss.scan(/\n+/) then
            # do nothing
          when text = ss.scan(/.*/) then
            action { [:end, text] }
          else
            text = ss.string[ss.pos .. -1]
            raise ScanError, "can not match (#{state.inspect}): '#{text}'"
          end
        else
          raise ScanError, "undefined state: '#{state}'"
        end # token = case state

      next unless token # allow functions to trigger redo w/ nil
    end # while

    raise "bad lexical result: #{token.inspect}" unless
      token.nil? || (Array === token && token.size >= 2)

    # auto-switch state
    self.state = token.last if token && token.first == :state

    token
  end # def _next_token
end # class
