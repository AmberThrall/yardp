# frozen_string_literal: true

require_relative '../lib/yardp'

# A JSON parser
class JSONParser < Yardp::Grammar
  start(:json)

  token(:HEX, /[0-9a-f]/, :i)

  rule(:json) { value }
  rule(:value) { object | array | string | number | t('true') | t('false') | t('null') }
  rule(:object) { (t('{') >> members? >> t!('}')) }
  rule(:members) { member >> (t(',') >> member!).repeat }
  rule(:member) { string >> t!(':') >> value! }
  rule(:array) { (t('[') >> values? >> t!(']')) }
  rule(:values) { value >> (t(',') >> value!).repeat }
  rule(:string, strip_whitespace: false) { t('"') >> character.repeat >> t!('"') }
  rule(:character) { t(/[^"\\]/) | (t('\\') >> escape!) }
  rule(:escape) { t(%w[" \\ / b f n r t]) | (t('u') >> HEX * 4) }
  rule(:number, strip_whitespace: false) { integer >> fraction? >> exponent? }
  rule(:integer) { t('-').maybe >> (t(/[1-9][0-9]*/) | t('0')) }
  rule(:fraction) { t('.') >> t(/[0-9]+/) }
  rule(:exponent) { t(%w[E e]) >> t(/[+-]?[1-9][0-9]*/) }

  def parse(text)
    tree = super(text)
    tree.delete_rule(:ws, recursive: true)
    # tree.pretty_print
    tree.graphviz.output(png: 'json.png')
    handle_value(tree[:value])
  end

  private

  def handle_value(value)
    case value[0].rule
    when :object then handle_object(value[0])
    when :array then handle_array(value[0])
    when :string then handle_string(value[0])
    when :number then handle_number(value[0])
    when :terminal
      case value[:terminal].string
      when 'true' then true
      when 'false' then false
      when 'null' then nil
      end
    end
  end

  def handle_object(object)
    members = object[:members]
    return {} if members.nil?

    hash = {}
    Array(members[:member]).each do |member|
      hash[handle_string(member[:string]).to_sym] = handle_value(member[:value])
    end
    hash
  end

  def handle_array(array)
    values = array[:values]
    return [] if values.nil?

    array = Array(values[:value])
    array.map { |v| handle_value v }
  end

  def handle_string(str)
    Array(str[:character]).join
  end

  def handle_number(number)
    s = number[:integer].string
    s += number[:fraction].to_s
    s += number[:exponent].to_s
    number[:fraction].nil? ? s.to_i : s.to_f
  end
end

TEST_JSON = %(
  {"widget": {
      "debug": true,
      "window": {
          "title": "Sample K\u00F6nfabulator Widget",
          "name": "main_window",
          "width": 500.0,
          "height": 500.0
      },
      "image": {
          "src": "Images\nSun.png",
          "name": "sun1",
          "hOffset": 250,
          "vOffset": 250,
          "alignment": "center"
      },
      "text": {
          "data": "Click Here",
          "size": 36,
          "style": "bold",
          "name": "text1",
          "hOffset": 250,
          "vOffset": 100,
          "alignment": "center",
          "onMouseUp": "sun1.opacity = (sun1.opacity / 100) * 90;"
      }
  }}
)

parser = JSONParser.new
pp parser.parse(TEST_JSON)
