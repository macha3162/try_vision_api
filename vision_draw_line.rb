require 'bundler'
Bundler.require
require 'base64'
require 'json'
require 'net/https'
require 'pp'


#IMAGE_FILE = './sea.jpeg'
IMAGE_FILE = './faces.jpeg'
#IMAGE_FILE = './angry.jpg'
#IMAGE_FILE = './hori.jpg'

API_KEY = 'AIzaSyCvJnXUnBQXAL1D5mwSdWoVflxSSOUtL3o'
VISION_API = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"

# 画像をbase64にエンコード
base64_image = Base64.strict_encode64(File.new(IMAGE_FILE, 'rb').read)

# APIリクエスト用のJSONパラメータの組み立て
vision_body = {requests: [{image: {content: base64_image}, features: [{type: 'FACE_DETECTION', maxResults: 5}]}]}.to_json
response = RestClient.post VISION_API, vision_body, {content_type: :JSON}

result = Hashie::Mash.new(JSON.parse(response.body, {symbolize_names: true}))

boundingPolys = result.responses.first.faceAnnotations.map { |face| face.boundingPoly.vertices.map { |value| [value.x, value.y] }.flatten.each_slice(4).to_a }
fdBoundingPolys = result.responses.first.faceAnnotations.map { |face| face.fdBoundingPoly.vertices.map { |value| [value.x, value.y] }.flatten.each_slice(4).to_a }


points = result.responses.first.faceAnnotations.map do |face|
  face.landmarks.map do |landmark|
    [landmark.position.x, landmark.position.y, landmark.position.x+1, landmark.position.y+1]
  end.to_a
end


img = Magick::Image.read(File.new(IMAGE_FILE, 'rb'))[0]
gc = Magick::Draw.new
gc.stroke('red')


boundingPolys.each do |faces|
  faces.each do |plot|
    gc.line(*plot)
  end
end


fdBoundingPolys.each do |faces|
  faces.each do |plot|
    gc.line(*plot)
  end
end

gc.stroke('blue')
points.each do |faces|
  faces.each do |plot|
    gc.circle(*plot)
  end
end

gc.draw(img)
img.write("draw.jpg")







