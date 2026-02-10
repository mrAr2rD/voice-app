module ApplicationHelper
  # Преобразует HEX цвет в rgba с прозрачностью
  # hex_to_rgba("#FF5500", 0.2) => "rgba(255, 85, 0, 0.2)"
  def hex_to_rgba(hex, alpha = 1.0)
    hex = hex.gsub("#", "")
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end
end
