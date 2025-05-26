//
//  App.swift
//  Example
//
//  Created by 秋星桥 on 1/20/25.
//

import SwiftUI

@main
struct TheApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                Content()
                    .toolbar {
                        ToolbarItem {
                            Button {
                                NotificationCenter.default.post(name: .init("Play"), object: nil)
                            } label: {
                                Image(systemName: "play")
                            }
                        }
                    }
                    .navigationTitle("MarkdownView")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(.stack)
            .frame(minWidth: 200, maxWidth: .infinity)
        }
    }
}

import MarkdownParser
import MarkdownView

final class ContentController: UIViewController {
    let scrollView = UIScrollView()
    let measureLabel = UILabel()

    private var markdownTextView: MarkdownTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)

        markdownTextView = MarkdownTextView()
        scrollView.addSubview(markdownTextView)

        measureLabel.numberOfLines = 0
        measureLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        measureLabel.textColor = .label

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(play),
            name: .init("Play"),
            object: nil
        )
    }

    @objc func play() {
        let parser = MarkdownParser()
        print(#function, Date())
        DispatchQueue.global().async { [self] in
            parser.reset()
            for char in testDocument {
                autoreleasepool {
                    let document = parser.feed(.init(char))
                    DispatchQueue.main.asyncAndWait {
                        let date = Date()
                        self.markdownTextView.nodes = document
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                        let time = Date().timeIntervalSince(date)
                        self.measureLabel.text = String(format: "Time: %.4f ms", time * 1000)
                    }
                }
            }
            parser.reset()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        scrollView.frame = view.bounds
        let width = view.bounds.width - 32

        let contentSize = markdownTextView.boundingSize(for: width)
        scrollView.contentSize = contentSize
        markdownTextView.frame = .init(
            x: 16,
            y: 16,
            width: width,
            height: contentSize.height
        )

        measureLabel.removeFromSuperview()
        measureLabel.frame = .init(
            x: 16,
            y: (scrollView.subviews.map(\.frame.maxY).max() ?? 0) + 16,
            width: width,
            height: 50
        )
        scrollView.addSubview(measureLabel)
        scrollView.contentSize = .init(
            width: width,
            height: measureLabel.frame.maxY + 16
        )

        let offset = CGPoint(
            x: 0,
            y: scrollView.contentSize.height - scrollView.frame.height
        )
        _ = offset
        scrollView.setContentOffset(offset, animated: false)
    }
}

struct Content: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> ContentController {
        ContentController()
    }

    func updateUIViewController(_: ContentController, context _: Context) {}
}

let testDocument = ###"""
## Markdown 测试数据
### 简介
Markdown 是一种轻量级标记语言，它允许人们使用易读易写的纯文本格式编写文档。以下是一个包含各种 Markdown 元素的测试数据。

### 标题
#### 四级标题
##### 五级标题
###### 六级标题

这是一段普通的文本，包括**加粗文字**和*斜体文字*。你也可以使用***加粗斜体文字***或~~删除线文字~~。

### 列表
#### 无序列表
* 这是一个无序列表项
* 这是另一个无序列表项
  * 这是一个嵌套的无序列表项
  * 这是另一个嵌套的无序列表项

#### 有序列表
1. 这是一个有序列表项
2. 这是另一个有序列表项
   1. 这是一个嵌套的有序列表项
   2. 这是另一个嵌套的有序列表项

### 任务列表
- [x] 已完成的任务
- [ ] 未完成的任务

### 一些算数

当 $a \ne 0$ 时，方程 $ax^2 + bx + c = 0$ 有两个解，分别为 $x = {-b \pm \sqrt{b^2-4ac} \over 2a}$。

### 表格

| 表头1 | 表头2 | 表头3 |
| --- | --- | --- |
| 单元格1 | 单元格2 | 单元格3 |
| 单元格4 | 单元格5 | 单元格6 |
| 长单元格内容 | 短内容 | 又一个长单元格内容 |

### 链接和图片

这是一个[链接](https://www.example.com)。你也可以添加一个图片：![图片描述](https://www.example.com/image.jpg)

### 代码块

```java
// 这是一个 Java 代码块
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

### 引用块
> 这是一个引用块。
> 你可以在这里写一些引用的文字。

### 分隔线
---

### 脚注
这是一个包含脚注的句子[^1]。

### 定义列表
术语1
: 定义1

术语2
: 定义2

### 缩写
*[HTML]: 超文本标记语言

### Emoji
你可以使用 Emoji 来增加趣味 😊。

### 流程图
```mermaid
graph LR;
    A[开始] --> B{条件};
    B -->|yes| C[执行];
    B -->|no| D[结束];
    C --> D;
```

### 时序图
```mermaid
sequenceDiagram;
    participant Alice;
    participant Bob;
    Alice->>Bob: 消息;
    Bob->>Alice: 回复;
```

### 扩展内容

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed sit amet nulla auctor, vestibulum magna sed, convallis ex.

[^1]: 这是脚注的内容。
"""###
