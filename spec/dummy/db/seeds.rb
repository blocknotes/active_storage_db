# frozen_string_literal: true

4.times do |i|
  io = Rails.root.join("public/globe.svg").open
  Post.find_or_create_by!(title: "Post #{i + 1}") do |post|
    post.assign_attributes(content: "Some content for post #{i + 1}")
    if i.even?
      post.some_file.attach(io: io, filename: "img#{i + 1}.svg")
    end
  end
end
