



interface UserInfo {
  avatar?: string;
  name: string;
}

@Component
export struct AvatarComponent {
  @Prop user: UserInfo;
  @Prop avatarSize: number;

  build() {
    if (this.user.avatar) {
      Image(this.user.avatar)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .objectFit(ImageFit.Cover);
    } else {
      Text(this.user.name.charAt(this.user.name.length - 1))
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .backgroundColor('#D32F2F')
        .fontColor('#fff')
        .fontSize(this.avatarSize * 0.4)
        .textAlign(TextAlign.Center);
    }
  }
}
