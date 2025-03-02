require 'base64'
require 'json'
require 'net/https'

module Vision
  class << self
    def get_image_data(image_file)
      # APIのURL作成
      api_url = "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['Google_API_KEY']}"

      # 画像をbase64にエンコード
      base64_image = Base64.encode64(image_file.tempfile.read)

      # APIリクエスト用のJSONパラメータ
      params = {
        requests: [{
          image: {
            content: base64_image
          },
          features: [
            {
              type: 'LABEL_DETECTION'
            }
          ]
        }]
      }.to_json

      # Google Cloud Vision APIにリクエスト
      uri = URI.parse(api_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      response = https.request(request, params)
      response_body = JSON.parse(response.body)
      # APIレスポンス出力
      if (error = response_body['responses'][0]['error']).present?
        raise error['message']
      else
        # 英語のラベルを取得
        labels = response_body['responses'][0]['labelAnnotations'].pluck('description').take(3)

        # 日本語に翻訳
        labels.map { |label| translate_text(label) }
      end
    end

    private

    def translate_text(text)
      translate_url = "https://translation.googleapis.com/language/translate/v2?key=#{ENV['Google_API_KEY']}"

      params = {
        q: text,
        target: 'ja', # 翻訳先の言語（日本語）
        format: 'text'
      }.to_json

      uri = URI.parse(translate_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      response = https.request(request, params)
      response_body = JSON.parse(response.body)

      response_body.dig('data', 'translations', 0, 'translatedText') || text
      
    end
  end
end