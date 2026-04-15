import { ss } from '@/utils/storage'
import { t } from '@/locales'
import { homeStore } from "@/store";
const LOCAL_NAME = 'userStorage'
const backgroundImage = homeStore.myData.session.backgroundImage ?? "https://t.alcy.cc/fj/"

export interface UserInfo {
  avatar: string
  name: string
  backgroundImage: string
  description: string
}

export interface UserState {
  userInfo: UserInfo
}

export function defaultSetting(): UserState {
  return {
    userInfo: {
      avatar: 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAES7Vhp29KhX3UblQlxFpJ35A4jT--v8wACPiMAAp3j4Fa2pu-1KNhMcTsE.png',
      name:  t('mjset.sysname'),//'AI绘图',
      description: 'Star on <a href="https://keyhub.vip" class="text-blue-500" target="_blank" >Key Hub</a>',
    },
  }
}

export function getLocalState(): UserState {
  const localSetting: UserState | undefined = ss.get(LOCAL_NAME)
  return { ...defaultSetting(), ...localSetting }
}

export function setLocalState(setting: UserState): void {
  ss.set(LOCAL_NAME, setting)
}
