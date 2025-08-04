# Documentation

Thư mục này chứa tài liệu cho dự án RbxUtils sử dụng MkDocs.

## Xem tài liệu

### Phát triển (Development)
Để chạy documentation server trong chế độ development:

```bash
mkdocs serve
```

Sau đó mở trình duyệt và truy cập `http://127.0.0.1:8000`

### Build tài liệu
Để build tài liệu thành static site:

```bash
mkdocs build
```

Kết quả sẽ được tạo trong thư mục `site/`

## Cấu trúc

- `index.md` - Trang chủ documentation
- `utils/` - Tài liệu cho các utility modules
  - `Structure.md` - Tài liệu cho Structure system
- `mkdocs.yml` - File cấu hình MkDocs (ở thư mục root)

## Thêm tài liệu mới

1. Tạo file `.md` mới trong thư mục phù hợp
2. Cập nhật `nav` section trong `mkdocs.yml`
3. Viết nội dung bằng Markdown

## Theme và styling

Dự án sử dụng Material theme cho MkDocs với:
- Dark/Light mode toggle
- Indigo color scheme
- Responsive design
