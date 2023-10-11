require 'tanakai'
require 'uri'

class SispeqSpider < Tanakai::Base
  @name = 'utfpr_spider'
  @engine = :selenium_firefox
  @start_urls = ['https://sistemas2.utfpr.edu.br/ords/f?p=113:23']
  # rubocop:disable Layout/LineLength
  @config = {
    user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.84 Safari/537.36',
    before_request: { delay: 4..7 }
  }
  # rubocop:enable Layout/LineLength

  SKIP_ERRORS = [Capybara::ElementNotFound, Selenium::WebDriver::Error::StaleElementReferenceError]

  HEADERS = {
    'PESQPROJTITULOPORTVC' => :title,
    'UNIDCODNR' => :city,
    'COD_GRANDE_AREA' => :area,
    'ARCACODCAPESNR' => :capes,
    'NOME_PROPONENTE' => :proposer,
    'PESQPCROINICIODT' => :init_date,
    'PESQPCROTERMINODT' => :final_date,
    'PESQPROJPACHAVEPORTVC' => :key_words,
    'PESQPROJRESUMOPORTVC' => :resumo
  }.freeze

  # rubocop:disable Lint/UnusedMethodArgument,Layout/LineLength
  def parse(response, url:, data: {})
    @params_to_send = { project: {} }
    first_page = response.css(css_selector)
    parse_infos_and_send_to_integration(first_page)

    while browser.find(:xpath, "//*[@id='report_R234673011732010621']/div/table[2]/tbody/tr/td/table/tbody/tr/td[4]/a").click
      response = browser.current_response

      parse_infos_and_send_to_integration(response.css(css_selector))
    end
  rescue StandardError => e
    if SKIP_ERRORS.include? e.class
      Rails.logger.info "Just finished, exception: #{e}, message: #{e.message}"

      return
    end

    Rails.logger.info "The UTFPR Spider is crash, exception: #{e}, message: #{e.message}"
  end
  # rubocop:enable Lint/UnusedMethodArgument,Layout/LineLength

  private

  def css_selector
    'div#report_R234673011732010621 table.t-Report-report tbody tr td'
  end

  def parse_infos_and_send_to_integration(infos)
    infos.each do |data|
      header = data.attributes['headers'].text

      @params_to_send[:project][HEADERS[header]] = data.text

      # TODO: REST CLIENT PRA MANDAR PRO SERVIÇO QUE REGISTRAR
    end
  end
end
