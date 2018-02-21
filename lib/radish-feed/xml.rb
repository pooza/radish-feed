require 'rexml/document'
require 'radish-feed/renderer'

module RadishFeed
  class XML < Renderer
    attr :message, true

    def to_s
      return xml.to_s
    end

    private
    def xml
      raise 'messageが未定義です。' unless @message
      xml = REXML::Document.new
      xml.add(REXML::XMLDecl.new('1.0', 'UTF-8'))
      xml.add_element(REXML::Element.new('result'))
      message = xml.root.add_element('message')
      message.add_text(@message[:response][:message] || 'error')
      return xml
    end
  end
end
