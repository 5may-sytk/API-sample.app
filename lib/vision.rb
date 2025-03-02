require 'base64'
require 'json'
require 'net/https'

module Vision
  class << self
    def check_image_safety(image_file)
      api_url = "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['Google_API_KEY']}"
      base64_image = Base64.encode64(image_file.tempfile.read)

      params = {
        requests: [{
          image: { content: base64_image },
          features: [{ type: 'SAFE_SEARCH_DETECTION' }] # ✅ ラベル検出なし
        }]
      }.to_json

      uri = URI.parse(api_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      response = https.request(request, params)
      response_body = JSON.parse(response.body)

      # 🔹 不適切画像のチェック
      safe_search = response_body['responses'][0]['safeSearchAnnotation']
      is_safe = safe_search ? evaluate_safety(safe_search) : true

      is_safe
    end

    # ✅ `SAFE_SEARCH_DETECTION` の判定基準
    def evaluate_safety(safe_search)
      threshold = %w[LIKELY VERY_LIKELY]

      # いずれかのカテゴリが基準を超えたら「不適切」と判定
      is_adult = threshold.include?(safe_search["adult"])
      is_violence = threshold.include?(safe_search["violence"])
      is_medical = threshold.include?(safe_search["medical"])
      is_racy = threshold.include?(safe_search["racy"])

      # どれか1つでも基準を超えていれば「不適切」
      !(is_adult || is_violence || is_medical || is_racy)
    end
  end
end