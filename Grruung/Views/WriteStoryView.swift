//
//  WriteStoryView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/2/25.
//

import SwiftUI

struct WriteStoryView: View {
    
    @State private var diaryText: String = ""
    
    private var isPlaceholderVisible: Bool {
        diaryText.isEmpty
    }

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
         return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        print("Image tapped!")
                    }) {
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-15))
                            .foregroundColor(.gray)
                            .padding(.leading)
                    }
                    .padding(.leading, 20)
                    Spacer()

                    Text(currentDateString)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.trailing)
                        
                    Spacer() // Push date towards the center/right
                }
                .padding(.top) // Add padding above the HStack

                // TextEditor for multi-line input
                ZStack(alignment: .topLeading) {
                    // TextEditor itself
                    TextEditor(text: $diaryText)
                        .frame(minHeight: 150) // Give it some minimum height
                        .border(Color.clear) // Hide default border if any

                    // Placeholder Text - shown only if diaryText is empty
                    if isPlaceholderVisible {
                        Text("오늘 하루 \"쿼카\"에게 들려주고 싶은 이야기가 있나요?")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.top, 8) // Align placeholder with TextEditor's default padding
                            .padding(.leading, 5)
                            .allowsHitTesting(false) // Make placeholder non-interactive
                    }
                }
                .padding(.horizontal) // Add horizontal padding to the text editor area

                Spacer() // Pushes content to the top
            }
            .navigationTitle("이야기 들려주기") // Hide the default large navigation title area
            .navigationBarTitleDisplayMode(.inline) // Use inline style for title if needed
            .navigationBarItems(trailing:
                Button("저장") {
                    // Action for the save button
                    print("Save button tapped!")
                    print("Diary Text: \(diaryText)")
                
                // TODO: Add your save logic here
                
                }
            )
             .background(Color(UIColor.systemGray6).ignoresSafeArea())
        }
    }
}

struct DiaryEntryView_Previews: PreviewProvider {
    static var previews: some View {
        WriteStoryView()
    }
}
