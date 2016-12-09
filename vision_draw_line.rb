require 'bundler'
Bundler.require
require 'base64'
require 'json'
require 'net/https'
require 'matrix'
require 'pp'


#IMAGE_FILE = './sea.jpeg'
IMAGE_FILE = './blob.png'
#IMAGE_FILE = './angry.jpg'
#IMAGE_FILE = './hori.jpg'

API_KEY = 'AIzaSyCvJnXUnBQXAL1D5mwSdWoVflxSSOUtL3o'
VISION_API = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"


def draw_line(gc, pos)
  pos.each do |faces|
    faces.each do |plot|
      gc.line(*plot)
    end
  end
end

def draw_circle(gc, pos)
  pos.each do |faces|
    faces.each do |plot|
      gc.circle(*plot)
    end
  end
end

def draw_text(gc, img, pos, msg)
  gc.annotate(img, 0, 0, 5, pos, msg) do
    self.font = 'Verdana-Bold'
    self.fill = '#000000'
    self.align = Magick::LeftAlign
    self.stroke = 'transparent'
    self.pointsize = 10
    self.text_antialias = true
    self.kerning = 1
  end
end

def posture_score(nose_x, nose_y)
  [100 - (Vector[81, 81]-Vector[nose_x||0, nose_y||0]).r, 0].max
end

Dir::glob('images/*').each_with_index do |file, idx|
  base_name = File.basename(file)

# 画像をbase64にエンコード
  base64_image = Base64.strict_encode64(File.new(file, 'rb').read)

# APIリクエスト用のJSONパラメータの組み立て
  vision_body = {requests: [{image: {content: base64_image}, features: [{type: 'FACE_DETECTION', maxResults: 5}]}]}.to_json
  response = RestClient.post VISION_API, vision_body, {content_type: :JSON}

  result = Hashie::Mash.new(JSON.parse(response.body, {symbolize_names: true}))

  boundingPolys = result.responses.first.faceAnnotations.map { |face| face.boundingPoly.vertices.map { |value| [value.x, value.y] }.flatten.each_slice(4).to_a } rescue []
  fdBoundingPolys = result.responses.first.faceAnnotations.map { |face| face.fdBoundingPoly.vertices.map { |value| [value.x, value.y] }.flatten.each_slice(4).to_a } rescue []

  face_score = 0
  top_line, bottom_line = boundingPolys.pop
  if top_line && bottom_line
    pos_x = (top_line[0] + top_line[2])/2
    pos_y = (top_line[0] + bottom_line[2])/2
    face_score = posture_score(pos_x, pos_y)
  end

  nose_x = nose_y = 0
  points = result.responses.first.faceAnnotations.map do |face|
    face.landmarks.select { |l| l.type == 'NOSE_TIP' }.map do |landmark|
      nose_x =landmark.position.x
      nose_y =landmark.position.y
      [landmark.position.x, landmark.position.y, landmark.position.x+1, landmark.position.y+1]
    end.to_a
  end rescue []
  nose_score = posture_score(nose_x, nose_y)


  img = Magick::Image.read(File.new(file, 'rb'))[0]
  gc = Magick::Draw.new
  gc.stroke('green')

  draw_line(gc, boundingPolys)

  draw_line(gc, fdBoundingPolys)

  draw_circle(gc, points)

  gc.stroke('red')
  gc.fill('none')
  marker = [[80, 60, 40, 20, 0].map { |i| [81, 81, i, 81] }]
  draw_circle(gc, marker)


  draw_text(gc, img, 10, "nose: #{nose_score}")
  draw_text(gc, img, 25, "face: #{face_score}")


  face_score
  gc.draw(img)
  img.write("results/#{base_name}")
end





