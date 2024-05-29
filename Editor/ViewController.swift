//
//  ViewController.swift
//  Editor
//
//  Created by iain on 28/05/2024.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let scrollview = NSTextView.scrollableTextView()
        let editor = EditorView(with: lorem)
        
        scrollview.documentView = editor
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        editor.autoresizingMask = [.width, .height]
        
        view.addSubview(scrollview)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollview.trailingAnchor),
            view.topAnchor.constraint(equalTo: scrollview.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor)
        ])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController {
    var lorem: String { """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tempor iaculis suscipit. Sed suscipit tortor erat, vitae ornare nisi feugiat eu. Donec efficitur porttitor tellus, et molestie sapien imperdiet eget. Mauris at odio in dui ultrices congue. Cras a varius ante. Donec ipsum sem, faucibus nec eleifend in, interdum at mi. Cras eget risus aliquet, semper sem vitae, porta risus. Ut eu faucibus est, et mollis nisl. Etiam suscipit pulvinar varius. Praesent interdum ipsum non tortor convallis porta.

Quisque egestas fringilla sodales. Curabitur luctus rutrum risus a ultrices. Aliquam justo est, elementum in efficitur sed, condimentum sed sem. Praesent molestie sagittis enim, in fermentum nunc posuere sed. Vivamus est justo, mollis et urna nec, iaculis lobortis orci. In imperdiet dolor felis, et elementum lorem efficitur in. Phasellus pulvinar lectus mi, tincidunt imperdiet tellus mollis vitae. Aenean et urna lacus. Quisque malesuada nulla quis iaculis efficitur. Suspendisse sagittis, arcu id dictum vestibulum, nulla augue bibendum lectus, sit amet rutrum lacus massa sed mauris. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Interdum et malesuada fames ac ante ipsum primis in faucibus. Vivamus ex ex, tincidunt ac nisl vel, viverra vehicula lorem.

Morbi eleifend turpis a mi ultrices pellentesque. In eu egestas turpis, nec fermentum tortor. Proin elit ipsum, interdum a efficitur et, bibendum id purus. In at nisi sollicitudin, suscipit mi non, scelerisque lectus. Sed vel suscipit nisl. Nullam porttitor turpis at nisl porta fringilla. Integer aliquet felis eget elit accumsan suscipit. In sit amet dui cursus, cursus est non, eleifend lorem. Maecenas laoreet, dolor mattis tristique pretium, sapien tellus dignissim nulla, eget finibus leo arcu ac turpis. Aenean eu magna sagittis, hendrerit ex eu, luctus lorem. Vestibulum auctor, urna vel dictum tincidunt, sapien enim tincidunt felis, ac vestibulum lorem orci eget augue. Nulla magna mi, malesuada vel efficitur a, varius nec felis. Nunc mattis finibus lacus sit amet viverra. Fusce eget porttitor ligula. Etiam suscipit sodales maximus. Nunc eu turpis quam.

Sed mauris arcu, pellentesque in accumsan ac, fermentum eget orci. Morbi at facilisis tellus, vel feugiat metus. Sed facilisis felis ultricies ligula imperdiet, a ornare libero vulputate. Nunc at enim lobortis, semper massa in, fringilla nulla. Fusce dignissim neque id risus posuere, a hendrerit risus feugiat. Suspendisse pharetra velit tellus, vitae laoreet lacus viverra in. Phasellus ante lectus, viverra ut molestie id, sollicitudin ut mi. Duis placerat lectus vel dui varius congue.

Fusce dictum, neque id tincidunt blandit, nulla libero sagittis ante, in vulputate erat urna non ante. Aenean sed mauris vulputate, consequat est ac, dapibus lorem. Etiam scelerisque id purus quis lacinia. Vestibulum vel nisi ac risus tristique commodo. Nullam id libero vitae magna placerat tincidunt. Donec porta consectetur massa, at consequat ligula vehicula nec. Proin pretium nisl vel velit molestie luctus. Ut quis elementum eros, ac tincidunt sapien. Vivamus viverra diam dolor, eu cursus orci fermentum a. Nullam non gravida ipsum. Sed varius lacinia dui id pretium. Nam in aliquam ante, at varius sem. Phasellus nec odio sem. Cras porttitor est lobortis elit sollicitudin venenatis. Maecenas at arcu dictum, pretium nibh at, semper turpis."
"""
    }
}

