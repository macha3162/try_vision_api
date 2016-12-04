require 'bundler'
Bundler.require
require 'base64'
require 'json'
require 'net/https'
require 'pp'


#IMAGE_FILE = './sea.jpeg'
#IMAGE_FILE = './faces.jpeg'
#IMAGE_FILE = './angry.jpg'
IMAGE_FILE = './hori.jpg'

API_KEY = 'AIzaSyCvJnXUnBQXAL1D5mwSdWoVflxSSOUtL3o'
VISION_API = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"
TRANSLATION_API = "https://translation.googleapis.com/language/translate/v2"

feelings = %w(joyLikelihood sorrowLikelihood angerLikelihood surpriseLikelihood underExposedLikelihood blurredLikelihood headwearLikelihood)

# 画像をbase64にエンコード
base64_image = Base64.strict_encode64(File.new(IMAGE_FILE, 'rb').read)

# APIリクエスト用のJSONパラメータの組み立て
vision_body = {requests: [{image: {content: base64_image}, features: [{type: 'FACE_DETECTION', maxResults: 5}]}]}.to_json
response = RestClient.post VISION_API, vision_body, {content_type: :JSON}

result = Hashie::Mash.new(JSON.parse(response.body, {symbolize_names: true}))
pp result.responses.first.faceAnnotations.map{ |people | people.select { |k, v| feelings.include?(k) } }





