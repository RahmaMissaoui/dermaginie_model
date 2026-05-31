# main.py
from config import OUTPUT_DIR
from preprocess import preprocess_all_images
from smote import apply_smote_augmentation
from cdcgan import train_cdcgan_for_class  # import other functions as needed
import pandas as pd


def main():
    print("🚀 Starting HAM10000 Preprocessing Pipeline v2\n")

    # Step 1: Preprocess
    df_base = preprocess_all_images()

    # Step 2: SMOTE
    df_smote = apply_smote_augmentation(df_base)

    # Step 3: GAN (Optional - slow on CPU)
    # df_gan = run_gan_augmentation(df_base)   # Uncomment when ready

    df_gan = pd.DataFrame(columns=['image_id', 'dx', 'label', 'source'])  # placeholder

    # Merge all
    df_base['source'] = 'real'
    df_final = pd.concat([df_base[['image_id', 'dx', 'label', 'source']],
                          df_smote, df_gan], ignore_index=True)

    df_final = df_final.sample(frac=1, random_state=SEED).reset_index(drop=True)
    df_final.to_csv(os.path.join(OUTPUT_DIR, 'metadata.csv'), index=False)

    print("\n🎉 Pipeline Completed!")
    print(f"Total images: {len(df_final)}")
    print(df_final['source'].value_counts())
    print(df_final['dx'].value_counts())


if __name__ == "__main__":
    main()