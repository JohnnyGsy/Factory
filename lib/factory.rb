# frozen_string_literal: true

# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?
class Factory
  def self.new(*key_args, keyword_init: false, &block)
    if key_args.empty?
      raise ArgumentError,
            "wrong number of arguments (given #{args.size}, expected 1+)"
    end
    if key_args[0].is_a?(String)
      unless key_args.first[0] == key_args.first[0].upcase
        raise NameError, "identifier #{key_args.first} needs to be constant"
      end

      @name = key_args.shift
    end
    subclass = Class.new(self) do
      class << self
        define_method :new do |*args|
          instance = allocate
          instance.send(:initialize, *args)
          instance
        end
      end

      define_method :initialize do |*args|
        @params = key_args
        if keyword_init
          unknown_keywords = @params - args[0].keys
          raise ArgumentError, "unknown keywords: #{unknown_keywords.join(', ')}" if unknown_keywords.any?

          @table = args[0]
        else
          raise ArgumentError, 'factory size differs' if args.size > @params.size

          @table = @params.map(&:to_sym).zip(args).to_h
        end
        @table.each_pair do |key, value|
          instance_variable_set("@#{key}", value)
          self.class.instance_eval { attr_accessor key.to_sym }
        end
      end
      class_eval(&block) if block_given?
    end
    @name ? Factory.const_set(@name, subclass) : subclass
  end

  def each(&block)
    if block_given?
      @table.values.each(&block)
    else
      to_enum
    end
  end

  def to_h
    @table
  end

  def values
    @table.values
  end

  alias to_a values

  def size
    @table.size
  end

  alias length size

  def members
    @table.keys
  end

  def values_at(*select)
    @table.values.values_at(*select)
  end

  def select(&block)
    @table.values.select(&block)
  end

  def each_pair(&block)
    if block_given?
      @table.each_pair(&block)
    else
      to_enum
    end
  end

  def [](key)
    if key.is_a?(Numeric)
      @table.values[key] || raise(IndexError, "offset #{key} too large for factory(size:#{@table.size})")
    elsif @table[key.to_sym]
      @table[key.to_sym]
    else
      raise NameError, "no member '#{key}' in factory"
    end
  end

  def []=(key, value)
    if key.is_a?(Numeric)
      if @table.keys.length > key
        @table[@table.keys[key]] = value
      else
        raise IndexError, "offset #{key} too large for factory(size:#{@table.size})"
      end
    elsif @table[key.to_sym]
      @table[key.to_sym] = value
      instance_variable_set("@#{key}", value)
    else
      raise NameError, "no member '#{key}' in factory"
    end
  end

  def hash
    arr = [self.class] + to_a
    arr.hash
  end

  def eql?(other)
    hash == other.hash
  end

  def ==(other)
    self.class == other.class && to_a == other.to_a ? true : false
  end

  def dig(*keys)
    @table.dig(*keys)
  end
end
